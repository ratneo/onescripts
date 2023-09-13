# onescripts

Put all my instra script here, including the docker or its related configs/resources.
All scripts are written based on stable Debian linux distribution.

## Fping

```bash
fping -c 2 -a -g 23.106.143.0/24  2>&1 | grep min
fping -c 2 -a < 45102-0-2095.txt  2>&1 | grep min
```
