# Qwen2.5 LLM Inference Code for Corebrum using Ollama
# This code is embedded in Corebrum's Python template which provides:
# - inputs: dict containing task parameters (prompt, model, temperature, etc.)
# - worker_id: string with worker identifier
# - result: variable we should set (will be printed as JSON by Corebrum)

import json
import sys
import urllib.request
import urllib.parse

# Suppress stderr to avoid polluting output
import io
sys.stderr = io.StringIO()

# Initialize result to None (Corebrum template does this, but being explicit)
result = None

try:
    # Extract parameters from inputs (provided by Corebrum template)
    prompt = inputs.get("prompt", "")
    model_name = inputs.get("model", "qwen2.5vl:3b")  # Default to available Ollama model
    max_tokens = inputs.get("max_tokens", 512)
    temperature = inputs.get("temperature", 0.7)
    
    # Map model names to Ollama model names
    # If user specifies "Qwen/Qwen2.5-7B-Instruct", try to use a similar Ollama model
    if "qwen" in model_name.lower() or "Qwen" in model_name:
        # Check available models and use the best match
        if "vl" in model_name.lower() or "vision" in model_name.lower():
            ollama_model = "qwen2.5vl:3b"
        else:
            # Try qwen2.5vl:3b as default, or use the model name directly if it's already an Ollama model
            ollama_model = model_name if ":" in model_name else "qwen2.5vl:3b"
    else:
        ollama_model = model_name
    
    if not prompt:
        result = {
            "error": "Prompt is required",
            "status": "failed"
        }
    else:
        # Use Ollama Chat API (better for instruction-tuned models like Qwen)
        ollama_url = "http://localhost:11434/api/chat"
        
        # Format prompt for instruction-tuned models
        # Qwen models work better with clear, direct instructions
        formatted_prompt = prompt.strip()
        
        # Build messages array with optional system prompt for Qwen models
        messages = []
        
        # Add system prompt for Qwen models to improve response quality
        if "qwen" in ollama_model.lower():
            messages.append({
                "role": "system",
                "content": "You are a helpful AI assistant. Provide clear, accurate, and informative responses."
            })
        
        # Add user prompt
        messages.append({
            "role": "user",
            "content": formatted_prompt
        })
        
        # Prepare request payload using chat format
        payload = {
            "model": ollama_model,
            "messages": messages,
            "stream": False,
            "options": {
                "temperature": temperature,
                "num_predict": max_tokens
            }
        }
        
        # Make request to Ollama
        data = json.dumps(payload).encode('utf-8')
        req = urllib.request.Request(
            ollama_url,
            data=data,
            headers={'Content-Type': 'application/json'}
        )
        
        try:
            with urllib.request.urlopen(req, timeout=300) as response:
                response_data = json.loads(response.read().decode('utf-8'))
                
                # Extract response text from chat API format
                # Chat API returns: {"message": {"role": "assistant", "content": "..."}, ...}
                message = response_data.get("message", {})
                response_text = message.get("content", "") if isinstance(message, dict) else ""
                
                # Fallback to "response" field if "message" format not found
                if not response_text:
                    response_text = response_data.get("response", "")
                
                # Set result (Corebrum template will print this as JSON)
                result = {
                    "text": response_text.strip(),
                    "model": ollama_model,
                    "provider": "ollama",
                    "status": "success",
                    "usage": {
                        "prompt_tokens": response_data.get("prompt_eval_count", 0),
                        "completion_tokens": response_data.get("eval_count", 0),
                        "total_tokens": response_data.get("prompt_eval_count", 0) + response_data.get("eval_count", 0)
                    }
                }
        except urllib.error.URLError as e:
            result = {
                "error": f"Failed to connect to Ollama API: {str(e)}. Make sure Ollama is running on localhost:11434",
                "status": "failed",
                "provider": "ollama"
            }
        except json.JSONDecodeError as e:
            result = {
                "error": f"Failed to parse Ollama response: {str(e)}",
                "status": "failed",
                "provider": "ollama"
            }
        except Exception as e:
            result = {
                "error": f"Ollama API error: {str(e)}",
                "status": "failed",
                "provider": "ollama"
            }
        
except Exception as e:
    # Handle all errors gracefully
    result = {
        "error": str(e),
        "status": "failed"
    }
