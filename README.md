# passwordless.sh
Remove all interactive password prompts for your desktop session

#### Execute by running as your current user:
```
curl --proto '=https' --tlsv1.2 -sSfL https://raw.githubusercontent.com/fallingcats/passwordless.sh/refs/heads/main/passwordless.sh | bash
```
This also works if priviliges have been elevated through `su`, `sudo` or `run0` for this session

#### Alternatively, explicitly specify a user:
Alternatively as root, replacing `{user}` with your user account:
```
curl --proto '=https' --tlsv1.2 -sSfL https://raw.githubusercontent.com/fallingcats/passwordless.sh/refs/heads/main/passwordless.sh | bash -s -- {user}
```

