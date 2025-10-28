#!/usr/bin/env python3
"""
Monitor twist commands from zenoh topic
"""
import zenoh
import struct
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def parse_twist_message(data):
    """Parse ROS2 geometry_msgs/Twist message"""
    try:
        if len(data) != 48:
            logger.error(f"Invalid twist message size: {len(data)} bytes (expected 48)")
            return None
        
        # Unpack linear velocities (x, y, z)
        linear_x, linear_y, linear_z = struct.unpack('<ddd', data[0:24])
        
        # Unpack angular velocities (x, y, z)
        angular_x, angular_y, angular_z = struct.unpack('<ddd', data[24:48])
        
        return {
            'linear': {'x': linear_x, 'y': linear_y, 'z': linear_z},
            'angular': {'x': angular_x, 'y': angular_y, 'z': angular_z}
        }
    except Exception as e:
        logger.error(f"Error parsing twist message: {e}")
        return None

def on_twist_received(sample):
    """Callback for when twist commands are received"""
    try:
        # Handle ZBytes properly
        if hasattr(sample.payload, 'data'):
            data = sample.payload.data
        else:
            data = bytes(sample.payload)
        logger.info(f"📨 Received twist command: {len(data)} bytes")
        
        twist = parse_twist_message(data)
        if twist:
            logger.info(f"🚗 Twist command:")
            logger.info(f"   Linear:  x={twist['linear']['x']:.3f}, y={twist['linear']['y']:.3f}, z={twist['linear']['z']:.3f}")
            logger.info(f"   Angular: x={twist['angular']['x']:.3f}, y={twist['angular']['y']:.3f}, z={twist['angular']['z']:.3f}")
            
            # Determine action
            if twist['linear']['x'] > 0:
                logger.info("🤖 Action: MOVING FORWARD")
            else:
                logger.info("🤖 Action: STOPPED")
        else:
            logger.error("❌ Failed to parse twist message")
        
        logger.info("---")
        
    except Exception as e:
        logger.error(f"Error processing twist command: {e}")

def main():
    logger.info("🚀 Starting twist command monitor...")
    
    # Open zenoh session
    config = zenoh.Config()
    session = zenoh.open(config)
    
    # Create subscriber for twist commands
    subscriber = session.declare_subscriber("rt/cmd_vel", on_twist_received)
    
    try:
        logger.info("📡 Listening for twist commands on rt/cmd_vel...")
        logger.info("Press Ctrl+C to stop")
        
        # Keep the program running
        import time
        while True:
            time.sleep(1)
    
    except KeyboardInterrupt:
        logger.info("🛑 Stopping twist command monitor...")
    
    except Exception as e:
        logger.error(f"Error in monitor: {e}")
    
    finally:
        # Clean up
        subscriber.undeclare()
        session.close()
        logger.info("✅ Twist command monitor stopped")

if __name__ == "__main__":
    main()
