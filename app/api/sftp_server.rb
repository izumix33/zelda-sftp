module SftpServer
  class API < Grape::API
    version 'v1', using: :path
    format :json
    prefix :api


    helpers do
      def not_exists?(username)
        check_cmd = "grep -e \"^#{username}:\" /etc/passwd | wc -l"
        `#{check_cmd}`.chop.to_i == 0
      end

      def create_user(username)
        require 'csv'
        # /etc/passwd
        # /etc/group
        # に100000以上で！
        # taka1:x:505:505::/home/taka1:/bin/bash
        # taka:x:503:
        puts `"sudo useradd #{username} -d /mnt/efs/#{username}"`

        # passwd_file = '/etc/passwd'
        # no = CSV.read(passwd_file, headers:false, col_sep:':').reduce(100000){|max, row| [max, row[2].to_i].max}
        # setup_user = []
        # setup_user << "echo #{username}:x:#{no}:#{no}::/mnt/efs/#{username}:/bin/bash | sudo tee --append #{passwd_file} > /dev/null"
        # setup_user << "echo #{username}:x:#{no}: | sudo tee --append /etc/group > /dev/null"
        # puts `#{setup_user.join(';')}`
      end

      def create_user_dir(username)
        setup_dirs = []
        setup_dirs << "sudo mkdir /mnt/efs/#{username}"
        setup_dirs << "sudo chown root:root /mnt/efs/#{username}"
        setup_dirs << "sudo mkdir /mnt/efs/#{username}/uploads"
        setup_dirs << "sudo mkdir /mnt/efs/#{username}/downloads"
        setup_dirs << "sudo chmod 755 /mnt/efs/#{username}"

        setup_dirs << "sudo mkdir /mnt/efs/#{username}/.ssh"
        setup_dirs << "sudo touch /mnt/efs/#{username}/.ssh/authorized_keys"
        setup_dirs << "sudo chown -R #{username}:#{username} /mnt/efs/#{username}/.ssh"
        setup_dirs << "sudo chown #{username}:#{username} /mnt/efs/#{username}/uploads"
        setup_dirs << "sudo chown #{username}:#{username} /mnt/efs/#{username}/downloads"
        puts `#{setup_dirs.join(';')}`
      end

      def update_authorized_keys(username)
        sftp_keys = ['ssh-dss AAAAB3NzaC1kc3MAAACBANLuDitegIgecMbpfeuG3ekw5ZU4awhbyNgH1iXs9suHaNu2b5bFaPZOy0FBdX7ju+uDTWl1PVJByoqBW/CfKCF4C6Ifiz4jIEEAIkAPSBrJ+oZWybHW8CXi9i4987hGupY8RL8MkfwIKijXx8tbsmrILuVNKlndc05IJVPtkZJTAAAAFQCmPLI1hTImZrxTht5tJjKd5cL4BQAAAIBTLH5XYoVp1zHi3jKSj8eb3O54fwESrh82HB7GDmogpXFqw8k2jmCJTdZOviO9o45WLyqcY8ZNN7Tnj7xhXp3uqcWn+iN59NhVHlirH5U6uKRviGfWSa/Vfs/hXJvdW7yQAOBj2wTq1VEzW6cSX5cENR6aWdDpTZSa8ffupQTlDQAAAIBc9WSXZozofIacd3armGFvDzkA12LlxpC+dOeL7sZST36OMwbdciuejFBg9XIMkB2eWtp/99lBqauKrXrfq3d1HHzk7NaDa2RyR879k6/jBDxuPOmiIYLCEd76mvFlhDZbmbmD+euPN3dwUmfbKWSoGRXF0ewlTNUZk1P0rOe1iQ== mix@MixMacBook.local',
                     'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBuGjDM73O8zFR/JM9Qe5uDa3Qgeqeplw0UWInF7eR02y+cvX5Jfe0buHTw30zq9VHwbdmzFElptLgrTFiPhjtHuh3UjT1nzpZk3QLhcWXBJv0RyOw+MMRnS2pXke/9RvSJ+tER7ZCA34AtPtXw4eYfoddw9EplBqRv6hdUxaHZ7pnhjoS/kIqDr8Ab2+Jg7gwODIFhDu9wGRK8J0r21VlFHEq0l2IkqcN/lgl5g+qQEtiA/GGH8OCIcZLThZ/Oow/GPkOOMZkcFXrINVjx118+r+TAwFEvHgujGQWMkjDROe+zV71GasPwwUKm2VySLP1hp+YsyS4bjiB0xt2iecv mix@MixMacBook-3.local', 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCtPnRbfplBUk85lMrwyuX76rqdDDDnKO5cxuGiaIbhdLYbvZtfv484DRSiB/+FvQPwwtLQP532gxa+E+ZqfMFtXgC60UQjC79Ho3f+W/O2aGFg+XnwFbNOSx3fAo8bznrDThCnRlv0kJcsLgTaUcXsq5HE2h6pMKC2M/HRZ0xrgBYIjpy06B05sTgCKyQjdhVVbJR9m0JP2ECQ1wvyzTEevTGk836sSJHi10hdPhuTUj26KsJmbIyg34m5rCCKn4MPPUAzzfXUXZWaKHyYaoqRTG3deSc3ia+HXt+HOGnALe0v24hir8thaSPL1tmqYYIme+eDuIAUnhq0uI5acmIl mix@MixMacBook-3.local']
        new_authorized_keys = sftp_keys.join("\n")

        # original = File.open("/mnt/efs/#{username}/.ssh/authorized_keys").read
        original = `sudo cat /mnt/efs/#{username}/.ssh/authorized_keys`
        unless new_authorized_keys == original
          File.open("tmp/#{username}_authorized_keys", 'w') { |fp| fp.write new_authorized_keys }
          copy_cmd = "sudo cp tmp/#{username}_authorized_keys /mnt/efs/#{username}/.ssh/authorized_keys"
          puts `#{copy_cmd}`
          File.delete("tmp/#{username}_authorized_keys")
        end
      end
    end


    # TODO: resource user_setup_resultsとか
    params do
      requires :username, type: String, desc: 'user name'
    end

    # TODO: getにしているがputの方がよい？D&A考えると叩けた方が良いかと。。
    get :execute do
      username = params[:username]
      if not_exists?(username)
        create_user(username)
        create_user_dir(username)
      end

      update_authorized_keys(username)
      'finish!!'
    end

    get :test do
      'test'
    end

  end
end