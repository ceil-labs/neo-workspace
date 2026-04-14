#!/bin/bash
cd /home/openclaw/.openclaw/workspace-neo/htb/academy/information-gathering-skills-assessment/raw_data
source ../../recon-env/bin/activate
python ReconSpider.py "http://dev.web1337.inlanefreight.htb:30516/"
