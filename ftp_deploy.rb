# This ruby script is a plugin for the Jekyll static website builder. It gives
# the user the option to deploy the generated site to a server via FTP.
#
# Copyright (c) 2017 Dylan Crocker
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

require "net/ftp"
require "highline/import"

# Recursively delete the contents of the specified directory.
def delete_ftp_dir(ftp, dir, skip=[])

    # Get list of contents and their parameters (ls -l).
    files_list = ftp.list(dir)

    # Iterate over the directory contents and delete files. Subdirectories are
    # deleted recursively.
    ftp.nlst(dir).each_with_index do |file, index|

        # Skip . and ..
        if file == "." or file == ".."
            next
        end

        # Skip any specified files or folders
        if skip.include?(file)
            next
        end

        # Create full path to item
        file_path = File.join(dir, file)

        # Based on the number of links determine if it is a file or directory.
        nlinks = files_list[index].split(" ")[1].to_i
        if nlinks < 2
            puts "Deleting:".red + " #{file_path}"
            ftp.delete(file_path)
        else
            delete_ftp_dir(ftp, file_path)
            puts "Deleting:".red + " #{file_path}"
            ftp.rmdir(file_path)
        end

    end

end # end delete_ftp_dir

# Recursively upload a folder to a server via FTP.
def upload_folder_ftp(ftp, folder, ftp_dir, skip=[])

    # Iterate through the directories contents - recursively handling
    # directories - and upload to the server.
    Dir.entries(folder).each do |file|

        # Skip . and ..
        if file == "." or file == ".."
            next
        end

        # Create the full path
        file_path = File.join(folder, file)
        ftp_path = File.join(ftp_dir, file)

        if File.directory?(file_path)
            puts "Creating server directory: ".magenta + "#{ftp_path}"
            ftp.mkdir(ftp_path)
            upload_folder_ftp(ftp, file_path, ftp_path, skip)
        else
            puts "Uploading: ".magenta +  " #{file_path}" + " to ".magenta + "#{ftp_path}"
            ftp.putbinaryfile(file_path, ftp_path)
        end

    end

end # end upload_folder_ftp

Jekyll::Hooks.register :site, :post_write do
    puts "Would you like to push to the server? (yes/no) "
    push_decision = gets
    if push_decision.chomp!.downcase == "yes"

        # Read the config file to get the FTP login info.
        deploy_settings = YAML.load_file("_config.yml")["ftp_deploy"]
        username = deploy_settings["ftp_username"]
        url = deploy_settings["ftp_url"]
        remote_dir = deploy_settings["ftp_dir"]

        begin
            # FTP Login
            password = ask("Enter FTP password: ") { |q| q.echo = "*" }
            puts "Logging into the server..."
            ftp = Net::FTP.new(url)
            ftp.login(username, password)
            puts "Logged in!"

            # Delete old site contents
            puts "Removing old site contents from server..."
            ignore_list = [".ftpquota", "cgi-bin"]
            delete_ftp_dir(ftp, ftp.pwd(), ignore_list)
            puts "Done!"

            # Push new site
            puts "Pushing site to server..."
            skip_list = [".DS_Store", "Icon?"]
            upload_folder_ftp(ftp, "_site", ftp.pwd, skip=skip_list)
            puts "\n\tDone! Website is now live.\n".yellow

        rescue
            print "Unable to login to FTP server. ".red
            puts "Please check the FTP username and password.".red
        end


    end
end
