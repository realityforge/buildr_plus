class Buildr::ZipTask
  private

  def create_from(file_map, transform_map)
    Zip::OutputStream.open name do |zip|
      seen = {}
      mkpath = lambda do |dir|
        dirname = (dir[-1..-1] =~ /\/$/) ? dir : dir + '/'
        unless dir == '.' || seen[dirname]
          mkpath.call File.dirname(dirname)
          zip.put_next_entry(dirname, compression_level)
          seen[dirname] = true
        end
      end

      paths = file_map.keys.sort
      paths.each do |path|
        contents = file_map[path]
        warn "Warning:  Path in zipfile #{name} contains backslash: #{path}" if path =~ /\\/
        mkpath.call File.dirname(path)

        entry_created = false
        to_transform = []
        transform = transform_map.key?(path)
        [contents].flatten.each do |content|
          if content.respond_to?(:call)
            unless entry_created
              entry = zip.put_next_entry(path, compression_level)
              entry.unix_perms = content.mode & 07777 if content.respond_to?(:mode)
              entry_created = true
            end
            if transform
              output = StringIO.new
              content.call output
              to_transform << output.string
            else
              content.call zip
            end
          elsif content.nil? || File.directory?(content.to_s)
            mkpath.call path
          else
            File.open content.to_s, 'rb' do |is|
              unless entry_created
                entry = zip.put_next_entry(path, compression_level)
                entry.unix_perms = is.stat.mode & 07777
                entry_created = true
              end
              if transform
                output = StringIO.new
                while data = is.read(4096)
                  output << data
                end
                to_transform << output.string
              else
                while data = is.read(4096)
                  zip << data
                end
              end
            end
          end
        end
        if transform_map.key?(path)
          zip << transform_map[path].call(to_transform)
        end
      end
    end
  end
end
