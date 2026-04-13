# Python Environment Management

## Quick Reference: pipx vs pip vs venv

| Tool | Use Case | Importable by Scripts? |
|------|----------|----------------------|
| `pipx` | Install CLI tools globally (isolated venvs) | ❌ No — each app is isolated |
| `pip` (system) | Install packages into system/user Python | ✅ Yes — but can break system packages |
| `pip` (inside venv) | Install packages into project virtualenv | ✅ Yes — clean and isolated |

## When `pipx` Fails for Scripts

```bash
pipx install scrapy          # Installs scrapy CLI only
python3 ReconSpider.py       # ❌ ModuleNotFoundError: No module named 'scrapy'
```

`pipx` creates an isolated virtual environment and only exposes CLI entry points to `PATH`. The Python interpreter running `ReconSpider.py` cannot see `pipx`-installed packages.

## Fix: Use a Virtual Environment

```bash
# Create venv in the project directory
python3 -m venv recon-env

# Activate it
source recon-env/bin/activate

# Install dependencies
pip install scrapy

# Run the script
python3 ReconSpider.py http://inlanefreight.com
```

## Re-activate Later

```bash
source recon-env/bin/activate
python3 ReconSpider.py <target>
```

## Alternative: System/User pip (Quick but Risky)

```bash
pip install --user scrapy
python3 ReconSpider.py http://inlanefreight.com
```

> ⚠️ `--user` avoids breaking system Python, but can still cause long-term dependency conflicts.

## Pattern for HTB Tools

When downloading a tool archive (ZIP/tar) that requires Python dependencies:

1. Extract to a dedicated directory
2. Create a venv inside that directory
3. Activate and `pip install -r requirements.txt` (or install manually)
4. Run the tool from within the activated venv

```bash
unzip ReconSpider.zip -d reconspider/
cd reconspider/
python3 -m venv .venv
source .venv/bin/activate
pip install scrapy
python3 ReconSpider.py <target>
```

## Deactivate venv

```bash
deactivate
```

This drops you back to the system Python and removes the prompt prefix.

---

## One-Liner Checklist

| Task | Command |
|------|---------|
| Create venv | `python3 -m venv .venv` |
| Activate (Linux/macOS) | `source .venv/bin/activate` |
| Activate (Windows CMD) | `.venv\Scripts\activate.bat` |
| Activate (Windows PowerShell) | `.venv\Scripts\Activate.ps1` |
| Install package | `pip install <package>` |
| Run script | `python3 script.py` |
| Deactivate | `deactivate` |
