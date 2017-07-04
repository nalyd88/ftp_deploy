# FTP Deploy Jekyll Plugin
Jekyll plugin for deploying the generated static site to a server via FTP.

## Usage
Copy `ftp_deploy.rb` to the `_plugins` folder of your Jekyll project and then
run `jekyll build`. When the site has built it will ask you if you want to
deploy, type `yes` to deploy. The FTP password will be asked for in the
terminal and the other required variables (username, FTP site URL, and remote
directory) will be read from the project's `_config.yml` file as shown below.

```yaml
# Add the following to the _config.yml file.
ftp_deploy:
    ftp_username: username@yourdomain.com
    ftp_url: ftp.yourdomain.com
    ftp_dir: /blog # or / for root
```

## Options

You can configure the software to skip certain files/folders by editing the
`ignore_list` and `skip_list` variables in the main script.

```ruby
# Example

# Items to ignore when cleaning the FTP deploy directory.
ignore_list = [".ftpquota", "cgi-bin"]

# ...

# Items to skip when deploying.
skip_list = [".DS_Store", "Icon?"]
```

## Requirements

This project uses the [Highline](https://github.com/JEG2/highline) gem.

## License

The software is covered under the MIT license.
