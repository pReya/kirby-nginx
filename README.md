# Running Kirby on Nginx

In its requirements, Kirby states that it is able to run on many different web servers. However in reality it seems that most of the time it is used on Apache servers. There are many reasons why Apache might be the preferred way to host Kirby:

Historically, Apache is pretty common among shared webhosting providers where many people host their Kirby sites. It's also very popular as a local development server because of tools like LAMP or MAMP which make it very easy to install Apache and PHP on your local computer.

## Nginx does not support `.htaccess`

One of the best arguments for using Apache is one of its convenience features: It can be configured through files (called `.htaccess`) within your project folder. So it's no wonder, Kirby ships with a `.htaccess` file which makes sure, that it should run flawlessly when the folder is dropped inside an Apache web root.

Because Nginx does not support `.htaccess` files [for performance reasons](https://www.nginx.com/resources/wiki/start/topics/examples/likeapache-htaccess/), it needs to be configured through a single, global config file. Most of the time, the config file also needs to be adjusted to the specific setup. There is not a single config file that works for all setups. This seems a little more intimidating to beginners – however it's really not that difficult and requires only about 20 lines of configuration to get Kirby running on Nginx.

A Nginx config file consists of contexts and directives. A directive is just a special keyword, followed by one or multiple values (e.g. `server_name localhost`). A context is a group for directives (e.g. `server {...}`).

Typically, when talking about a Nginx configuration, we don't need to modify the complete configuration, but only the `server` directive. This part will be embedded into a larger config file by default.

```nginx
server {  // Create a new virtual server for Kirby
  index index.php index.html; // If no specific file is requested, try these files
  server_name localhost; // This needs to be adjusted to your domain name
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

## Explanation

