"""
Task Generator Helper Functions
Functions to dynamically generate Corebrum task definitions for AGI agent
"""

import json
import uuid
from datetime import datetime
from typing import Dict, List, Any, Optional


def create_research_task(topic: str, depth: str = "comprehensive", subtopic: Optional[str] = None) -> Dict[str, Any]:
    """Create a research task definition"""
    task_name = f"research_{topic.replace(' ', '_').lower()}"
    if subtopic:
        task_name += f"_{subtopic.replace(' ', '_').lower()}"
    
    code = f"""
import json
import sys

topic = "{topic}"
depth = "{depth}"
subtopic = "{subtopic if subtopic else 'general'}"

# Simulated research (in real implementation, would use web search, APIs, etc.)
# For demo purposes, generate structured findings
findings = {{
    "topic": topic,
    "subtopic": subtopic,
    "depth": depth,
    "key_points": [
        f"{{topic}} is a rapidly evolving field",
        f"Recent developments in {{subtopic}} show significant progress",
        f"Applications of {{topic}} span multiple industries"
    ],
    "sources": ["research_analysis", "synthesis"],
    "timestamp": __import__("datetime").datetime.now().isoformat()
}}

result = {{
    "findings": findings,
    "status": "completed",
    "task_type": "research"
}}
"""
    
    return {
        "name": task_name,
        "version": "1.0",
        "description": f"Research task for {topic}" + (f" - {subtopic}" if subtopic else ""),
        "language": "python",
        "source": {
            "inline": {
                "code": code.strip()
            }
        },
        "inputs": [
            {
                "name": "topic",
                "type": "string",
                "required": True,
                "default_value": topic
            },
            {
                "name": "depth",
                "type": "string",
                "required": False,
                "default_value": depth
            }
        ],
        "outputs": [
            {
                "name": "findings",
                "type": "object",
                "description": "Research findings"
            },
            {
                "name": "status",
                "type": "string",
                "description": "Task status"
            }
        ],
        "requirements": {
            "memory_mb": 256,
            "cpu_cores": 1,
            "timeout_seconds": 300
        }
    }


def create_analysis_task(data: Any, analysis_type: str = "general") -> Dict[str, Any]:
    """Create an analysis task definition"""
    task_name = f"analysis_{analysis_type.replace(' ', '_').lower()}"
    
    code = f"""
import json
import sys

data = {json.dumps(data)}
analysis_type = "{analysis_type}"

# Perform analysis based on type
if analysis_type == "pattern_detection":
    analysis_result = {{
        "patterns_found": len(data.get("key_points", [])) if isinstance(data, dict) else 0,
        "pattern_types": ["trend", "correlation", "anomaly"],
        "confidence": 0.85
    }}
elif analysis_type == "synthesis":
    analysis_result = {{
        "synthesized_findings": data.get("findings", {{}}) if isinstance(data, dict) else {{}},
        "summary": "Synthesized analysis of provided data",
        "key_insights": ["Insight 1", "Insight 2", "Insight 3"]
    }}
else:
    analysis_result = {{
        "analysis_type": analysis_type,
        "data_processed": True,
        "insights": ["General insight from data analysis"]
    }}

result = {{
    "analysis": analysis_result,
    "status": "completed",
    "task_type": "analysis"
}}
"""
    
    return {
        "name": task_name,
        "version": "1.0",
        "description": f"Analysis task: {analysis_type}",
        "language": "python",
        "source": {
            "inline": {
                "code": code.strip()
            }
        },
        "inputs": [
            {
                "name": "data",
                "type": "object",
                "required": True,
                "description": "Data to analyze"
            },
            {
                "name": "analysis_type",
                "type": "string",
                "required": False,
                "default_value": analysis_type
            }
        ],
        "outputs": [
            {
                "name": "analysis",
                "type": "object",
                "description": "Analysis results"
            },
            {
                "name": "status",
                "type": "string",
                "description": "Task status"
            }
        ],
        "requirements": {
            "memory_mb": 512,
            "cpu_cores": 1,
            "timeout_seconds": 300
        }
    }


def create_synthesis_task(findings: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Create a synthesis task that combines multiple findings"""
    task_name = "synthesis_findings"
    
    code = """
import json
import sys

findings = """ + json.dumps(findings) + """

# Synthesize findings into comprehensive report
synthesized = {
    "total_findings": len(findings),
    "key_themes": [],
    "comprehensive_summary": "",
    "recommendations": []
}

# Extract key themes
all_themes = []
for finding in findings:
    if isinstance(finding, dict):
        themes = finding.get("key_points", [])
        if isinstance(themes, list):
            all_themes.extend(themes)

synthesized["key_themes"] = list(set(all_themes))[:10]  # Unique themes, limit to 10
synthesized["comprehensive_summary"] = f"Synthesized {len(findings)} research findings into comprehensive analysis"
synthesized["recommendations"] = [
    "Continue research in identified key areas",
    "Focus on high-impact applications",
    "Monitor emerging trends"
]

result = {
    "synthesis": synthesized,
    "status": "completed",
    "task_type": "synthesis"
}
"""
    
    return {
        "name": task_name,
        "version": "1.0",
        "description": "Synthesize multiple research findings into comprehensive report",
        "language": "python",
        "source": {
            "inline": {
                "code": code.strip()
            }
        },
        "inputs": [
            {
                "name": "findings",
                "type": "array",
                "required": True,
                "description": "List of findings to synthesize"
            }
        ],
        "outputs": [
            {
                "name": "synthesis",
                "type": "object",
                "description": "Synthesized findings"
            },
            {
                "name": "status",
                "type": "string",
                "description": "Task status"
            }
        ],
        "requirements": {
            "memory_mb": 512,
            "cpu_cores": 1,
            "timeout_seconds": 300
        }
    }


def create_computation_task(operation: str, inputs_data: Dict[str, Any]) -> Dict[str, Any]:
    """Create a computation task"""
    task_name = f"compute_{operation.replace(' ', '_').lower()}"
    
    if operation == "pi_calculation":
        code = f"""
import math

decimal_places = {inputs_data.get('decimal_places', 5)}
pi_value = round(math.pi, decimal_places)

result = {{
    "pi_value": pi_value,
    "decimal_places": decimal_places,
    "method": "math.pi rounded to {{}} decimals".format(decimal_places),
    "status": "completed",
    "task_type": "computation"
}}
"""
    elif operation == "factorial":
        code = f"""
import math

number = {inputs_data.get('number', 10)}
factorial_value = math.factorial(number)

result = {{
    "factorial": factorial_value,
    "input": number,
    "status": "completed",
    "task_type": "computation"
}}
"""
    else:
        code = f"""
# Generic computation
operation = "{operation}"
inputs = {json.dumps(inputs_data)}

result = {{
    "operation": operation,
    "result": "Computation completed",
    "inputs": inputs,
    "status": "completed",
    "task_type": "computation"
}}
"""
    
    return {
        "name": task_name,
        "version": "1.0",
        "description": f"Computation task: {operation}",
        "language": "python",
        "source": {
            "inline": {
                "code": code.strip()
            }
        },
        "inputs": [
            {
                "name": key,
                "type": type(value).__name__ if not isinstance(value, (dict, list)) else "object",
                "required": True,
                "default_value": value
            }
            for key, value in inputs_data.items()
        ],
        "outputs": [
            {
                "name": "result",
                "type": "object",
                "description": "Computation result"
            },
            {
                "name": "status",
                "type": "string",
                "description": "Task status"
            }
        ],
        "requirements": {
            "memory_mb": 256,
            "cpu_cores": 1,
            "timeout_seconds": 300
        }
    }


def create_job_from_task_definition(task_definition: Dict[str, Any], inputs: Dict[str, Any], queue: str = "user_tasks") -> Dict[str, Any]:
    """Create a Job object from a task definition for submission to Corebrum"""
    return {
        "task_id": str(uuid.uuid4()),
        "queue": queue,
        "task_definition": task_definition,
        "inputs": inputs,
        "priority": 0,
        "created_at": datetime.now().isoformat(),
        "timeout_seconds": 300
    }
