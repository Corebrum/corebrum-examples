#!/usr/bin/env python3
"""
Person following system that uses zenoh camera data and publishes twist commands
"""
import zenoh
import logging
import time
import struct
import requests
import base64
import cv2
import numpy as np

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def parse_ros2_image(payload):
    """Parse ROS2 sensor_msgs/Image message format manually (from working code)"""
    try:
        # Convert ZBytes to bytes if needed
        if hasattr(payload, 'data'):
            payload_bytes = payload.data
        else:
            payload_bytes = bytes(payload)
        
        logger.info(f"Payload size: {len(payload_bytes)} bytes")
        
        # Find the frame_id by looking for "camera" string
        camera_pos = payload_bytes.find(b'camera')
        logger.info(f"Camera position: {camera_pos}")
        
        if camera_pos == -1:
            logger.error("Could not find 'camera' frame_id in payload")
            return None
        
        # The frame_id length should be 4 bytes before "camera"
        frame_id_len_pos = camera_pos - 4
        if frame_id_len_pos < 0:
            logger.error("Invalid frame_id length position")
            return None
        
        frame_id_len = struct.unpack('<I', payload_bytes[frame_id_len_pos:frame_id_len_pos+4])[0]
        logger.info(f"Frame ID length: {frame_id_len}")
        
        # Calculate the offset after frame_id
        frame_id_end = camera_pos + frame_id_len
        
        # Parse image dimensions
        height = struct.unpack('<I', payload_bytes[frame_id_end:frame_id_end+4])[0]
        width = struct.unpack('<I', payload_bytes[frame_id_end+4:frame_id_end+8])[0]
        
        logger.info(f"Parsed dimensions: {width}x{height}")
        
        # Find the "rgb8" encoding string
        rgb8_pos = payload_bytes.find(b'rgb8')
        logger.info(f"RGB8 position: {rgb8_pos}")
        
        if rgb8_pos == -1:
            logger.error("Could not find 'rgb8' encoding in payload")
            return None
        
        # Calculate image data size and find matching resolution
        total_payload = len(payload_bytes)
        header_size = rgb8_pos + 5 + 1 + 4  # encoding + is_bigendian + step
        image_data_size = total_payload - header_size
        
        logger.info(f"Total payload: {total_payload}, Header size: {header_size}, Image data size: {image_data_size}")
        
        # Try common camera resolutions
        common_resolutions = [
            (640, 480), (800, 600), (1024, 768), (1280, 720), (1280, 960), 
            (1920, 1080), (1280, 1024), (1600, 1200)
        ]
        
        for w, h in common_resolutions:
            expected_size = w * h * 3  # 3 channels for RGB
            if abs(expected_size - image_data_size) < 100:  # Allow small tolerance for padding
                width, height = w, h
                logger.info(f"Matched resolution: {w}x{h}")
                break
        else:
            # Fallback to calculated dimensions
            pixels = image_data_size // 3
            width = int(pixels ** 0.5)
            height = pixels // width
            logger.info(f"Fallback resolution: {width}x{height}")
        
        # Get image data
        offset = rgb8_pos + 5 + 1 + 4  # encoding + is_bigendian + step
        image_data = payload_bytes[offset:]
        
        logger.info(f"Image data offset: {offset}, Image data length: {len(image_data)}")
        
        # Convert ROS2 Image to OpenCV format
        image_array = np.frombuffer(image_data, dtype=np.uint8)
        
        # Truncate to expected size if there's extra data
        expected_pixels = height * width * 3
        if len(image_array) > expected_pixels:
            image_array = image_array[:expected_pixels]
        
        image_array = image_array.reshape((height, width, 3))
        
        # Convert RGB to BGR for OpenCV
        image_bgr = cv2.cvtColor(image_array, cv2.COLOR_RGB2BGR)
        
        logger.info(f"Successfully parsed ROS2 image: {image_bgr.shape}")
        return image_bgr
            
    except Exception as e:
        logger.error(f"Error parsing ROS2 image: {e}")
        import traceback
        traceback.print_exc()
        return None

def detect_human_with_qwen(image):
    """Use Qwen to detect if there's a human in the image"""
    try:
        # Resize image for faster processing
        resized_image = cv2.resize(image, (160, 90))
        
        # Convert image to base64
        _, buffer = cv2.imencode('.jpg', resized_image, [cv2.IMWRITE_JPEG_QUALITY, 85])
        image_base64 = base64.b64encode(buffer).decode('utf-8')
        
        # Prepare the request payload with more specific prompt
        payload = {
            "model": "qwen2.5vl:3b",
            "prompt": "Look at this image carefully. Is there a person (a man, woman, or person) clearly visible in this image? Answer only 'yes' or 'no'. Be very strict - only say 'yes' if you can clearly see a complete person.",
            "images": [image_base64],
            "stream": False
        }
        
        logger.info("🤖 Sending image to Qwen for human detection...")
        
        # Send request to Ollama
        response = requests.post(
            "http://localhost:11434/api/generate",
            json=payload,
            timeout=15
        )
        
        if response.status_code == 200:
            result = response.json()
            answer = result.get('response', 'no').strip().lower()
            human_detected = 'yes' in answer or 'person' in answer
            logger.info(f"🎯 Qwen Human Detection: {answer} -> {human_detected}")
            return human_detected, answer
        else:
            logger.error(f"Ollama API error: {response.status_code} - {response.text}")
            return False, "API error"
            
    except Exception as e:
        logger.error(f"Error detecting human with Qwen: {e}")
        return False, str(e)

def create_twist_message(linear_x, angular_z):
    """Create ROS2 geometry_msgs/Twist message in binary format"""
    try:
        # Create a buffer for the Twist message (6 doubles * 8 bytes = 48 bytes)
        buffer = bytearray(48)
        
        # Pack linear velocities (x, y, z)
        struct.pack_into('<ddd', buffer, 0, linear_x, 0.0, 0.0)
        
        # Pack angular velocities (x, y, z)
        struct.pack_into('<ddd', buffer, 24, 0.0, 0.0, angular_z)
        
        return bytes(buffer)
        
    except Exception as e:
        logger.error(f"Error creating Twist message: {e}")
        return create_twist_message(0.0, 0.0)

def on_image_received(sample, publisher):
    """Callback for when camera images are received from zenoh"""
    try:
        logger.info("📸 Received camera image from zenoh")
        
        # Parse the ROS2 image message
        image = parse_ros2_image(sample.payload)
        
        if image is not None:
            logger.info(f"📸 Image parsed: {image.shape[1]}x{image.shape[0]} pixels")
            
            # Save debug image
            debug_filename = f"/tmp/zenoh_follow_{int(time.time())}.jpg"
            cv2.imwrite(debug_filename, image)
            logger.info(f"💾 Debug image saved to: {debug_filename}")
            
            # Detect human using Qwen
            human_detected, qwen_answer = detect_human_with_qwen(image)
            
            # Get detailed description to see what Qwen is actually seeing
            try:
                resized_image = cv2.resize(image, (160, 90))
                _, buffer = cv2.imencode('.jpg', resized_image, [cv2.IMWRITE_JPEG_QUALITY, 85])
                image_base64 = base64.b64encode(buffer).decode('utf-8')
                
                desc_payload = {
                    "model": "qwen2.5vl:3b",
                    "prompt": "Describe what you see in this image in detail. What objects, people, or things are visible?",
                    "images": [image_base64],
                    "stream": False
                }
                
                desc_response = requests.post(
                    "http://localhost:11434/api/generate",
                    json=desc_payload,
                    timeout=10
                )
                
                if desc_response.status_code == 200:
                    desc_result = desc_response.json()
                    description = desc_result.get('response', 'No description')
                    logger.info(f"🔍 Qwen sees: {description}")
                else:
                    logger.warning("Could not get detailed description")
            except Exception as e:
                logger.warning(f"Could not get detailed description: {e}")
            
            # Create velocity command based on detection
            if human_detected:
                linear_x = 0.3  # Move forward
                angular_z = 0.0  # No turning
                logger.info("🤖 Human detected! Moving forward...")
            else:
                linear_x = 0.0  # Stop
                angular_z = 0.0  # No turning
                logger.info("🤖 No human detected. Stopping...")
            
            # Create and publish Twist message
            twist_data = create_twist_message(linear_x, angular_z)
            
            # Publish to zenoh
            publisher.put(twist_data)
            logger.info(f"🚗 Velocity command: linear_x={linear_x}, angular_z={angular_z}")
            logger.info(f"📤 Published twist command to rt/cmd_vel ({len(twist_data)} bytes)")
            logger.info("---")
            
        else:
            logger.error("❌ Failed to parse camera image")
    
    except Exception as e:
        logger.error(f"Error processing camera image: {e}")

def main():
    logger.info("🚀 Starting zenoh-based person following system...")
    
    # Open zenoh session
    config = zenoh.Config()
    session = zenoh.open(config)
    
    # Create publisher for twist commands
    publisher = session.declare_publisher("rt/cmd_vel")
    
    # Create subscriber for camera images with publisher callback
    def image_callback(sample):
        on_image_received(sample, publisher)
    
    subscriber = session.declare_subscriber("rt/camera/camera/color/image_raw", image_callback)
    
    try:
        logger.info("📡 Listening for camera images on rt/camera/camera/color/image_raw...")
        logger.info("📤 Will publish twist commands to rt/cmd_vel...")
        logger.info("Press Ctrl+C to stop")
        
        # Keep the program running
        while True:
            time.sleep(1)
    
    except KeyboardInterrupt:
        logger.info("🛑 Stopping zenoh person following system...")
    
    except Exception as e:
        logger.error(f"Error in zenoh person following: {e}")
    
    finally:
        # Clean up
        subscriber.undeclare()
        publisher.undeclare()
        session.close()
        logger.info("✅ Zenoh person following system stopped")

if __name__ == "__main__":
    main()
