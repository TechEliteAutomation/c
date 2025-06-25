# /home/u/c/web_app.py

import os
import sys
import json
from flask import Flask, jsonify, request
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from datetime import datetime
import google.generativeai as genai

sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from toolkit.ai.agent import OrchestratorAgent
from toolkit.utils.config import get_axiom_config
from toolkit.system.executor import read_file, create_file

app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}})

project_dir = os.path.dirname(os.path.abspath(__file__))
database_file = f"sqlite:///{os.path.join(project_dir, 'axiom.db')}"
app.config["SQLALCHEMY_DATABASE_URI"] = database_file
db = SQLAlchemy(app)

print("Initializing Axiom Agent...")
axiom_config = get_axiom_config()
axiom_agent = OrchestratorAgent(axiom_config)

AVAILABLE_TOOLS = {"read_file": read_file, "create_file": create_file}

# Database models remain the same...
class Conversation(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False, default="New Conversation")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    messages = db.relationship('Message', backref='conversation', lazy=True, cascade="all, delete-orphan")

class Message(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    conversation_id = db.Column(db.Integer, db.ForeignKey('conversation.id'), nullable=False)
    role = db.Column(db.String(50), nullable=False)
    content = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

@app.route('/api/conversations', methods=['POST'])
def create_conversation():
    new_convo = Conversation()
    db.session.add(new_convo)
    db.session.commit()
    return jsonify({"id": new_convo.id, "title": new_convo.title}), 201

@app.route('/api/conversations/<int:convo_id>/messages', methods=['POST'])
def add_message(convo_id):
    data = request.json
    user_content = data['content']
    # --- NEW: Get the model from the frontend request ---
    model_key = data.get('model', 'gemini-1.5-pro-latest') # Default to Gemini

    db.session.add(Message(conversation_id=convo_id, role="user", content=user_content))
    db.session.commit()

    messages_from_db = Message.query.filter_by(conversation_id=convo_id).order_by(Message.created_at.asc()).all()
    chat_history = [{"role": m.role, "content": m.content} for m in messages_from_db]
    
    # --- The logic now depends on the model ---
    if model_key.startswith("gemini"):
        # Gemini flow with native tool calling
        response = axiom_agent.get_response(chat_history, "conversational_core", model_key)
        if response.candidates and response.candidates[0].content.parts and response.candidates[0].content.parts[0].function_call:
            function_call = response.candidates[0].content.parts[0].function_call
            tool_name = function_call.name
            tool_args = {key: value for key, value in function_call.args.items()}
            if tool_name in AVAILABLE_TOOLS:
                result = AVAILABLE_TOOLS[tool_name](**tool_args)
                response = axiom_agent.clients["gemini-1.5-pro-latest"].model.send_message(
                    [genai.Part(function_response=genai.protos.FunctionResponse(name=tool_name, response={"result": result}))],
                    history=response.history
                )
        final_response_text = response.text
    else:
        # Ollama flow (no tool calling for now)
        final_response_text = axiom_agent.get_response(chat_history, "conversational_core", model_key)

    db.session.add(Message(conversation_id=convo_id, role="model", content=final_response_text))
    db.session.commit()
    
    return jsonify({"role": "model", "content": final_response_text})

# Other endpoints remain the same...
@app.route('/api/conversations', methods=['GET'])
def get_conversations():
    conversations = Conversation.query.order_by(Conversation.created_at.desc()).all()
    return jsonify([{"id": c.id, "title": c.title} for c in conversations])

@app.route('/api/conversations/<int:convo_id>/messages', methods=['GET'])
def get_messages(convo_id):
    messages = Message.query.filter_by(conversation_id=convo_id).order_by(Message.created_at.asc()).all()
    return jsonify([{"role": m.role, "content": m.content} for m in messages])

@app.route('/api/workspace/files', methods=['GET'])
def get_workspace_files():
    workspace_path = os.path.join(project_dir, 'workspace')
    if not os.path.exists(workspace_path):
        os.makedirs(workspace_path)
        return jsonify([])
    all_files = []
    for root, _, files in os.walk(workspace_path):
        for name in files:
            all_files.append(name)
    return jsonify(all_files)

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(debug=True, port=5001)
