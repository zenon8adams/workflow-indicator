# workflow-indicator
A collection of bash script for indicating workflow status

### Indicator States
  * 🟤 - Build in progress
  * 🟢 - Build is successful
  * 🔴 - Build failed or cancelled
  * ⚫ - Build is in an unknown state

### Screenshot
<img src="https://github.com/zenon8adams/workflow-indicator/blob/master/screenshot.png" alt="screenshot"/>

### Requirement
  Requires installation of fish shell
  For Debian based systems, run:
```sh
  sudo apt install fish
```
  For Fedora based systems, run:
```sh
  sudo yum install fish
```
  For OS X, run:
```sh
  brew install fish
```

### Installing
```sh
  git clone https://github.com/zenon8adams/workflow-indicator
  cd workflow-indicator
  ./install.sh
```

### Notes
 * Only Github workflow is currently tested.
 * Only fish-shell is supported.
 * To show status of private repositories,
   your github token must be available at ~/.git-credentials
