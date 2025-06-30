# PowerShell script to help working with AD development.
# It bases on git worktree so you should read about that: https://git-scm.com/docs/git-worktree
# Your GIT GUI app should support git worktree (e.g. Fork)
#
# Benefits:
# - You can easly manage more than one ticket on your PC (source code and AD installations)
#   - AD ticket has its own worktree (source code copy), runners (bats to start AD and IDE) and AD instance.
# - You can easly install/reinstall AD specific for ticket
# - Tou do not need to set envirionment variables for AD - runners do it automatically
#
# Requirements:
# - Set environment variables (used by runners):
#   DELPHI_PATH=C:\Program Files (x86)\Embarcadero\Studio\20.0\bin\bds.exe
#   RIDER_PATH=C:\Program Files\JetBrains\JetBrains Rider 2025.1\bin\rider64.exe
#   VS_PATH=C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\IDE\devenv.exe
#
# - Personalize directories:
#   1) Create/select directory with X2 clonned (e.g. $srcAdRootDirectory = "C:\Develop\X2") - it will be used as git workflow source and for main branch
#   2) Create empty directory for source codes - worktree (e.g. $srcRootDirectory = "C:\Dev")
#   3) Create empty directory for AD installers ($adRootDirectory = "C:\Altium")
#   4) Create directory with runners (e.g. $runnersRootDirectory = "C:\Dev\!Runners") and paste Example runners here (from MC)!
#   5) SchDev branch directory (create it using git worktree or clone X2 again) (e.g. $schDevDirectory = "C:\Dev\X2-sch-dev")
#
# Workflow:
# 1) Select NEW ticket for development (workflow when you have already started ticket is not supported).
# 2) Create new item in workItems array below (paste ticket number and input SHORT description) - description will be normalized and used for new branch name.
# 2a) if you wont skip -SchTeam siffix set Alien to true
# 3) Run script
# 4) Select ticket by inputing its number
# 5) Select `Start ticket`
# 6) Drink coffe
# 7) you can use new runners to start Rider/VS/Delphi - you can do the job
# 8) Now you can use this script to reinstall AD (from main again or from your branch
#
# Known bugs
# You can work only one ticket at a time (when you start bat from second ticket when first is curently running, Rider/VS does not refresh environment variables!