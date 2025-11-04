from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from datetime import datetime
import random
import os
import threading
import webbrowser

app = Flask(
    __name__,
    static_folder=os.path.join(os.path.dirname(__file__), '..', 'frontend'),
    static_url_path=''
)
CORS(app)  # Enable CORS for frontend communication

# Task storage (in-memory for simplicity)
tasks = []

def calculate_green_score(hours, energy_level):
    """Calculate green score based on hours and energy level"""
    base_score = 100
    energy_multipliers = {"Low": 0.8, "Medium": 1.0, "High": 1.2}
    multiplier = energy_multipliers.get(energy_level, 1.0)
    # Lower hours = better score, but energy level matters
    score = base_score - (hours * 5) + (multiplier * 10)
    return max(0, min(100, score))

@app.route('/tasks', methods=['GET'])
def get_tasks():
    """Get all tasks"""
    return jsonify(tasks)

@app.route('/tasks', methods=['POST'])
def create_task():
    """Create a new task"""
    data = request.json
    task = {
        "task_name": data.get("task_name"),
        "hours": data.get("hours", 1),
        "category": data.get("category", "General"),
        "energy_level": data.get("energy_level", "Medium"),
        "green_score": calculate_green_score(data.get("hours", 1), data.get("energy_level", "Medium")),
        "id": len(tasks) + 1
    }
    tasks.append(task)
    return jsonify(task), 201

@app.route('/analytics', methods=['GET'])
def get_analytics():
    """Get analytics data"""
    if not tasks:
        return jsonify({
            "avg_green_score": 0,
            "distribution": {},
            "tips": ["Add some tasks to see analytics!"]
        })
    
    # Calculate average green score
    avg_green_score = sum(t["green_score"] for t in tasks) / len(tasks)
    
    # Calculate distribution by category
    distribution = {}
    for task in tasks:
        category = task.get("category", "General")
        distribution[category] = distribution.get(category, 0) + 1
    
    # Generate tips
    tips = []
    if avg_green_score < 50:
        tips.append("Your green score is low. Try scheduling tasks during off-peak hours.")
    if any(t["hours"] > 8 for t in tasks):
        tips.append("Consider breaking down long tasks into smaller chunks.")
    if len([t for t in tasks if t["energy_level"] == "High"]) > len(tasks) * 0.5:
        tips.append("Mix high and low energy tasks for better efficiency.")
    
    if not tips:
        tips.append("Great job! Your task schedule looks green and efficient.")
    
    return jsonify({
        "avg_green_score": avg_green_score,
        "distribution": distribution,
        "tips": tips
    })

# Static file routes for local/dev: serve frontend from Flask
@app.route('/')
def serve_index():
    return send_from_directory(app.static_folder, 'index.html')

@app.route('/<path:path>')
def serve_static(path):
    return send_from_directory(app.static_folder, path)

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))

    def _open_browser():
        # Only auto-open for local runs (skip in containers/CI by allowing opt-out)
        if os.environ.get('OPEN_BROWSER', '1') == '1':
            try:
                webbrowser.open(f"http://127.0.0.1:{port}")
            except Exception:
                pass

    threading.Timer(0.8, _open_browser).start()
    app.run(host='0.0.0.0', port=port, debug=False)
