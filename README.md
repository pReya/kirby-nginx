# Running Kirby on Nginx

In its requirements, Kirby states that it is able to run on many different web servers. However in reality it seems that most of the time it is used on Apache servers. Historically, Apache is pretty common among shared webhosting providers where many people host their Kirby sites. It's also very popular as a local development server because of tools like LAMP/MAMP/WAMP which make it very easy to install Apache and PHP on your local computer. Even though Nginx has been around for more than 15 years and is widely considered to be more modern and more performant than Apache, it's often seen as more complicated or not as beginner-friendly.

## Nginx does not support `.htaccess`

One of the best arguments for using Apache is one of its convenience features: It can be configured through files (called `.htaccess`) within your projects' folders. So it's no wonder, Kirby ships with a `.htaccess` file which makes sure, that it should run flawlessly whenever Kirby is dropped into an Apache web root.

But this convenience comes at a cost: speed. All these `.htaccess` files have to be read and interpreted at every single request. So, because Nginx does not support `.htaccess` files [for performance reasons](https://www.nginx.com/resources/wiki/start/topics/examples/likeapache-htaccess/), it needs to be configured through a single, global config file. Most of the time, the config file also needs to be adjusted to the very specific server setup. Where Apache uses modules to include PHP, Nginx also does this in its global config file. This means, there is not a single config file that works out of the box, which could be shipped with Kirby. So the process of configuring Nginx seems a little more intimidating to beginners – however it's really not that difficult and requires only about 20 lines of configuration to get Kirby running on Nginx.

## Contexts and Directives
Generally speaking, a Nginx config file consists of contexts and directives. A directive is just a special keyword, followed by one or multiple values (e.g. `server_name localhost`) and ends with semicolon. A context is a group and a scope for these directives (e.g. `server {...}`). The order of directives does not matter.

Typically, when talking about a Nginx configuration, we don't need to modify the complete configuration or start completely from scratch, because Nginx comes with a very reasonable default config. We only only need to create a new `server` context for our Kirby page. This part will be autmatically embedded into a larger config file by default, which we don't need to deal with at all.

So, let's go look at a typical server block for a Kirby setup line by line:

```nginx
server {
  listen 8080;
  index index.php index.html;
  server_name localhost;
  root /usr/share/nginx/html;

  location / {
    try_files $uri $uri/ /index.php$is_args$args;
  }

  location ~* \.php$ {
    try_files $uri =404;
    fastcgi_pass php:9000;
    include fastcgi.conf;
    fastcgi_split_path_info ^(.+\.php)(/.+)$;
    fastcgi_param PATH_INFO $fastcgi_path_info;
    fastcgi_param SERVER_PORT 8080;
  }
}
```

## Explanation

```
server {
  listen 8080;
```
With the server context, we're creating a new virtual server for our Kirby page, which we're going to configure with all the following directives, which are indented by one level. With the `listen` directive, we're telling Nginx, on which port it should listen. This directive is optional – if you omit it, Nginx will listen on the default port 80.

```
  index index.php index.html;
```

The `index` directive contains the names of files, which Nginx will try to serve, if the given request path does not directly match a file in the directory. Typically we want the `index.php` file to have a higher priority than the `index.html` file.

```
  server_name localhost;
```

The `server_name` directive tells Nginx, which requests it should accept for the given virtual server. This needs to be adjusted to your setup. If you're running Nginx locally, your probably want this to be `localhost` and if you're running it on the web, it should contain your domain name, e.g. `server_name www.mykirbysite.com`. You can also put down multiple server names, for example with `www` and without (e.g. `server_name www.mykirbysite.com mykirbysite.com`).


```
   root /usr/share/nginx/html;
```

This is a very important directive, as it tells Nginx where your web root is located. The files in the given directory will be served by Nginx. This should typically be the base folder of your Kirby project folder, or you should copy/extract the content of the Kirby repo/ZIP file to this location.

```
  location / {
    try_files $uri $uri/ /index.php$is_args$args;
  }
```

This block is extremly important, and probably the most "unique" part about runnig Kirby on Nginx. Without this block, links and images in Kirby will nowt work correctly. Kirby uses a so called "front controller", which means, that all requests to the Kirby site need to go through a single entrance point (which is `index.php`). Kirby will internally forward/handle the requests to the proper place. So, even if you're just trying to request an image somewhere in your content folder, the request still needs to go through `index.php` and cannot be answered by the webserver directly (e.g. Kirby needs to decide, whether to generate a Thumbnail or not). The `try_files` directive tells Nginx where, what files it should serve, if there is no direct match for the given path. By adding `/index.php$is_args$args` to this list, we make sure that every request gets to the Kirby front controller.


```
  location ~* \.php$ {
    try_files $uri =404;
```

This `location` block configures the communication between Nginx and PHP. The `~*` after the location keyword is a modifier, to make the following regular expression case insensitive (this means, that `.php` and `.PHP` files will both be handled by this block. Let's look at the regular expression `\.php$` in more detail:
- `\.` the backslash is an escape sequence, so the following character (a period) will be treated as an actual period, and not as a placeholder (which a period normally means)
- `php$` the dollar sign at the end of php means, that php needs to be at the end of a path (e.g. it will match `/my/folder/index.php` but not `/my/folder/index.php/morestuff`
The following line `try_files $uri =404;` is very important, and often missing in Nginx tutorials. It makes sure, that only existing files will be interpreted by PHP. If this is missing, PHP will do some crazy stuff to find a file matching this request, which may result in security problems.


```
    fastcgi_pass php:9000;
    include fastcgi.conf;
```

This is the actual handover to the PHP interpreter. The `fastcgi_pass` takes the IP or unix socket to a PHP FPM process. So this settings depends on your specific setup. If you're using docker, you can just put down the name of your FPM container. If you're running PHP FPM on the same system. you can use localhost followed by the port number. Including `fastcgi.conf` will properly set some global PHP variables like `SCRIPT_NAME` and others.
