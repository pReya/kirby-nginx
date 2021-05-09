# Running Kirby on Nginx

In its requirements, Kirby states that it is able to run on many different web servers. However in reality it seems that most of the time it is used on Apache servers. There are many reasons why Apache might be the preferred way to host Kirby:

Historically, Apache is pretty common among shared webhosting providers where many people host their Kirby sites. It's also very popular as a local development server because of tools like LAMP or MAMP which make it very easy to install Apache and PHP on your local computer.

## Nginx does not support `.htaccess`

One of the best arguments for using Apache is one of its convenience features: It can be configured through files (called `.htaccess`) within your project's folders. So it's no wonder, Kirby ships with a `.htaccess` file which makes sure, that it should run flawlessly whenever Kirby is dropped into an Apache web root.

But this convenience comes at a cost: speed. All these `.htaccess` files have to be read and interpreted at every single request. So, because Nginx does not support `.htaccess` files [for performance reasons](https://www.nginx.com/resources/wiki/start/topics/examples/likeapache-htaccess/), it needs to be configured through a single, global config file. Most of the time, the config file also needs to be adjusted to the very specific setup. Where Apache uses modules to include PHP, Nginx also does this in its global config file. This means, there is not a single config file that works out of the box, which could be shipped with Kirby. So the process of configuring Nginx seems a little more intimidating to beginners – however it's really not that difficult and requires only about 20 lines of configuration to get Kirby running on Nginx.

## Contexts and Directives
Generally speaking, a Nginx config file consists of contexts and directives. A directive is just a special keyword, followed by one or multiple values (e.g. `server_name localhost`). A context is a group and a scope for these directives (e.g. `server {...}`).

Typically, when talking about a Nginx configuration, we don't need to modify the complete configuration or start from scratch, because Nginx comes with a very reasonable default config. We only only need to create a new `server` context for our Kirby page. This part will be autmatically embedded into a larger config file by default, which we don't need to deal with at all.

So, let's go look at a typical config file for a Kirby setup line by line:

```nginx
server {                      // Create a new virtual server for Kirby
  index index.php index.html; // If no specific file is requested, try these files
  server_name localhost;      // This needs to be adjusted to your domain name
  error_log /var/log/nginx/error.log;
  access_log /var/log/nginx/access.log;
  root /usr/share/nginx/html; // This is where you need to put your files

  location / {
    try_files $uri $uri/ /index.php$is_args$args;
  }

  location ~* \.php$ {.                          // Configuration for PHP files
    try_files $uri =404;                         // Important for security reasons
    fastcgi_pass php:9000;                       // Handover to PHP
    fastcgi_index index.php;                     
    include fastcgi.conf;                        // This will make sure, that the $SERVER variable in PHP is correctly set, which Kirby uses a lot
    fastcgi_split_path_info ^(.+\.php)(/.+)$;
    fastcgi_param PATH_INFO $fastcgi_path_info;
    fastcgi_param SERVER_PORT 8080;
  }
}
```

## Explanation

```
server {
  index index.php index.html;
```

With the server context, we're creating a new virtual server for our Kirby page, which we're going to configure with all the following directives, which are indented by one level. The `index` directive contains the names of files, which Nginx will try to serve, if the given request path does not match a file in the directory. Typically we want the PHP file to have a higher priority than the HTML file.

```
  server_name localhost;
```

The `server_name` directive tells Nginx, which requests it should accept for the given virtual server. This needs to be adjusted to your setup. If you're running Nginx locally, your probably want this to be `localhost` and if you're running this on the web, it should contain your domain name, e.g. `server_name www.mykirbysite.com`. You can also put down multiple server names, for example with `www` and without (e.g. `server_name www.mykirbysite.com mykirbysite.com`).

