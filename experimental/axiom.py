# axiom.py

import argparse
from toolkit.ai.agent import OrchestratorAgent
from toolkit.utils.config import get_axiom_config

def main():
    """Main entry point for the mode-based Axiom CLI."""
    parser = argparse.ArgumentParser(description="Axiom: A Foundational Agentic Framework")
    
    parser.add_argument("--mode", type=str, required=True, 
                        choices=['generate-prompt', 'generate-plan', 'execute-plan'],
                        help="The operational mode for the agent.")
    
    parser.add_argument("--input", type=str, required=True,
                        help="The input text (e.g., an idea, a goal) or a path to an input file.")
                        
    parser.add_argument("--output-file", type=str, default="axiom_output.md",
                        help="The path to save the output file.")

    args = parser.parse_args()

    config = get_axiom_config()
    orchestrator = OrchestratorAgent(config=config)

    if args.mode == 'generate-prompt':
        orchestrator.generate_prompt_from_idea(args.input, args.output_file)
        
    elif args.mode == 'generate-plan':
        orchestrator.generate_plan_from_goal(args.input, args.output_file)
        
    elif args.mode == 'execute-plan':
        # For execute-plan, the input is a file path
        orchestrator.execute_plan_from_file(args.input)

if __name__ == "__main__":
    main()
