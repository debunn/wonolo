#! /usr/bin/env ruby

# Import the YAML library for parsing YAML playbooks
require 'yaml'

# Import the net/ssh library to handle sending multiple commands over SSH
require 'net/ssh'

# Verify parameters are passed as expected - otherwise return usage
if ARGV.length != 2
    puts 'Incorrect parameters were provided.  Usage:'
    puts $0 + ' <playbook_file> <inventory_file>'
    exit 1
end

class AnsibleLike
    def initialize(playbook_file, inventory_file)
        # Attempt to read and parse the playbook file provided
        begin
            @playbook = YAML.load(File.read(playbook_file))
        rescue 
            err_exit("Error reading playbook file: '#{playbook_file}'")
        end

        # Attempt to read each host in the inventory file provided
        begin
            @inventory = File.readlines(inventory_file, chomp: true)
        rescue
            err_exit("Error reading inventory file: '#{inventory_file}'")
        end

        # Verify playbook is a array of objects
        err_exit("Invalid playbook - please verify the file is in a valid YAML format") if !@playbook.kind_of?(Array)

        # Validate the playbook format
        @playbook.each_with_index do |play, item_num|
            i = item_num + 1 # Friendlier play number (not zero based)

            # Verify each playbook item has a name value
            err_exit("Invalid playbook - item #{i} has no name set") if !play.has_key?("name")

            # Verify each playbook item has a resource
            err_exit("Invalid playbook - item #{i}: '#{play["name"]}' has no resource set") if !play.has_key?("resource")

            # Verify resource is valid
            err_exit("Invalid playbook - item #{i}: '#{play["name"]}' has an invalid resource set: '#{play["resource"]}'") \
                if !['package', 'file', 'service', 'update', 'directory', 'command'].include? play["resource"]
        end
    end

    def execute
        # Run through each of the hosts in the inventory
        @inventory.each do |server|
            ssh = Net::SSH.start(server)
            # Run each of the playbook commands
            @playbook.each_with_index do |play, item_num|
                i = item_num + 1 # Friendlier play number (not zero based)
                puts "Executing playbook resource #{i}: #{play["resource"]} (#{play["name"]}) on server #{server}"
                play.merge!("play_num": i, "server": server, "ssh": ssh) # add extra variables to the play hash
                self.send(play["resource"], play) # call the AnsibleLike function associated with the resource, and include the play params
            end
            ssh.close
        end
    end

    # Controls the "package" resource execution
    def package(param_hash)
        puts param_hash[:ssh].exec!("sudo apt-get -y #{param_hash["action"]} #{param_hash["package_name"]}")
    end

    # Controls the "file" resource execution
    def file(param_hash)
        case param_hash["action"]
        when "create"
            output = param_hash[:ssh].exec!("touch #{param_hash["remote_file"]}").chomp
            if output.empty?
                puts "#{param_hash["remote_file"]} created successfully"
            else
                puts "Error creating file: '#{output}'"
            end
        when "upload"
            if system("scp #{param_hash["local_file"]} #{param_hash[:server]}:#{param_hash["remote_file"]} > /dev/null")
                puts "#{param_hash["local_file"]} copied successfully"
            else
                puts "Error uploading file: '#{param_hash["local_file"]}'"
            end
        when "delete"
            output = param_hash[:ssh].exec!("rm #{param_hash["remote_file"]}").chomp
            if output.empty?
                puts "#{param_hash["remote_file"]} deleted successfully"
            else
                puts "Error deleting file: '#{output}'"
            end
        end
    end

    # Controls the "service" resource execution
    def service(param_hash)
        output = param_hash[:ssh].exec!("sudo service #{param_hash["service_name"]} #{param_hash["action"]}").chomp
        if output.empty?
            puts "#{param_hash["service_name"]} #{param_hash["action"]} completed successfully"
        else
            puts "Error during service: '#{param_hash["service_name"]}' #{param_hash["action"]}: '#{output}'"
        end
    end

    # Controls the "update" resource execution
    def update(param_hash)
        puts param_hash[:ssh].exec!("sudo apt-get update")
    end

    # Controls the "directory" resource execution
    def directory(param_hash)
        case param_hash["action"]
        when "create"
            output = param_hash[:ssh].exec!("mkdir #{param_hash["remote_directory"]}").chomp
            if output.empty?
                puts "#{param_hash["remote_directory"]} created successfully"
            else
                puts "Error creating directory: '#{output}'"
            end
        when "delete"
            output = param_hash[:ssh].exec!("rmdir #{param_hash["remote_directory"]}").chomp
            if output.empty?
                puts "#{param_hash["remote_directory"]} removed successfully"
            else
                puts "Error removing directory: '#{output}'"
            end
        end
    end

    # Controls the "command" resource execution
    def command(param_hash)
        puts param_hash[:ssh].exec!("#{param_hash["remote_command"]}")
    end

    def err_exit(message)
        puts "#{message}"
        exit 1
    end
end

ansible_like = AnsibleLike.new(ARGV[0], ARGV[1])
ansible_like.execute
