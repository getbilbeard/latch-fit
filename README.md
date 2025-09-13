🚧 Roadmap
	•	Multi-profile support (track multiple moms/users)
	•	Cloud sync (backup data across devices)
	•	Dark mode polish
	•	More AI-powered insights

⸻

👩‍💻 Contributing
	1.	Fork the repo
	2.	Create a branch (feature/my-feature)
	3.	Commit changes
	4.	Push to branch
	5.	Open a Pull Request

⸻

📜 License

Choose a license (MIT recommended) — right now the repo has no license.

## Nutrition DB setup

The nutrition features can use the USDA FoodData Central API when an API key is available.

1. Sign up for an API key at https://fdc.nal.usda.gov/api-key-signup.html
2. Add the key to your environment as `FDC_API_KEY`.
   - In Codex, set it under project **Secrets**.
   - Locally, you can export it in your shell before running the app:
     ```bash
     export FDC_API_KEY=your_key_here
     ```
3. If no key is provided, the app falls back to a bundled offline database (`foods_min.json`).
