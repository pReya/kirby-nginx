# Running Kirby on Nginx

In its requirements, Kirby states that it is able to run on many different web servers. However in reality it seems that most of the time it is used on Apache servers. There are many reasons why Apache might be the preferred way to host Kirby:

Historically, Apache is pretty common among shared webhosting providers where many people host their Kirby sites. It's also very popular as a local development server because of tools like LAMP or MAMP which make local development setups a one-click thing.

Also Apache has a very big convenience feature: It can be configured through files (called `.htaccess`) within the web root folder. So it's no wonder, Kirby ships with a `.htaccess` file which makes sure, that it should run flawlessly when the folder is copied to an Apache web root.

Because Nginx does not support `.htaccess` files for performance reasons, it needs to be configure through a single, global config file. This seems a little more intimidating to beginners – however it's really not that difficult and requires only about 20 lines of config.

```nginx
server {
  index index.php index.html;
  server_name localhost;
  error_log /var/log/nginx/error.log;
  access_log /var/log/nginx/access.log;
  root /usr/share/nginx/html;

  location / {
    try_files $uri $uri/ /index.php$is_args$args;
  }

  location ~* \.php$ {
    try_files $uri =404;
    fastcgi_pass php:9000;
    fastcgi_index index.php;
    include fastcgi.conf;
    fastcgi_split_path_info ^(.+\.php)(/.+)$;
    fastcgi_param PATH_INFO $fastcgi_path_info;
    fastcgi_param SERVER_PORT 8080;
  }
}
```
