```
 ______     ______     __    __     ______     __         __     __     ______     ______     ______    
/\  == \   /\  == \   /\ "-./  \   /\  __ \   /\ \       /\ \  _ \ \   /\  __ \   /\  == \   /\  ___\   
\ \  __<   \ \  __<   \ \ \-./\ \  \ \  __ \  \ \ \____  \ \ \/ ".\ \  \ \  __ \  \ \  __<   \ \  __\   
 \ \_\ \_\  \ \_____\  \ \_\ \ \_\  \ \_\ \_\  \ \_____\  \ \__/".~\_\  \ \_\ \_\  \ \_\ \_\  \ \_____\
  \/_/ /_/   \/_____/   \/_/  \/_/   \/_/\/_/   \/_____/   \/_/   \/_/   \/_/\/_/   \/_/ /_/   \/_____/
```                                                                                                        

# redBorder Malware Sender

A generator to send random emails with malware or clean URLs and files.

![Malware](http://jaime-dulceguerrero.com/wp-content/uploads/2014/02/danger-32x32.png)
Caution: samples hosted in the "malware files" directory are real files with malware.

# Script options

To show options execute the script with `-h` argument.

```
Usage: ./sender sensor_ip_address domain [options]
    -e, --number-emails VALUE        Emails per minute (MAX 20)
    -u, --number-users VALUE         Number of users. It will be generated randomly (MAX 100)
    -m, --malware-prob VALUE         Probability to send and email with malware (range between 0 = all malware and 1 = all clean)
    -v, --verbose                    Verbose mode
    -d, --number_dsts VALUE          Number of email destinations per email
    -f, --max-files VALUE            Max number of files
    -r, --max-urls VALUE             Max number of urls
    -h, --help                       Prints the help
```

# Example

![Gif with the execution example](https://gitlab.redborder.lan/uploads/web-developers/redborder-malware-sender/76954f633c/malware.gif)
