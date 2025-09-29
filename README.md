# passwordless.sh
Remove all interactive user 

## As User
Execute by running as your current user:

```
curl --proto '=https' --tlsv1.2 --sSfL https://raw.githubusercontent.com/fallingcats/passwordless.sh/refs/heads/main/paswordless.sh | sudo bash -s
```

## As root
Alternatively as root, replacing `{user}` with your user account:
```
curl --proto '=https' --tlsv1.2 --sSfL https://raw.githubusercontent.com/fallingcats/passwordless.sh/refs/heads/main/paswordless.sh | bash -s -- {user}
```
If priviliges have been elevated through `su` or `sudo -i` there is no need to specify the user.
