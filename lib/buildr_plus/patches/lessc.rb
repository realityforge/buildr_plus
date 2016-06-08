def define_lessc_task(project, options = {})
  params = {
    :strict_math => true,
    :optimize => true,
    :strict_units => true,
    :target_dir => project._(:generated, :less, :main, :webapp),
    :target_subdir => 'css',
    :source_dir => project._(BuildrPlus::Less.default_less_path),
    :source_pattern => '**/[^_]*.less'
  }.merge(options)

  source_dir = params[:source_dir]
  source_pattern = params[:source_pattern]
  target_dir = params[:target_dir]

  files = FileList["#{source_dir}/#{source_pattern}"]

  if files.size > 0
    desc 'Preprocess Less files'
    compile_task = project.task('lessc' => [files]) do
      command = []
      command << 'lessc'
      command << '--no-js'
      command << "--strict-math=#{!!params[:strict_math] ? 'on' : 'off'}"
      command << "--strict-units=#{!!params[:strict_units] ? 'on' : 'off'}"

      if params[:optimize]
        command << '--clean-css="--s0"'
      end

      puts 'Compiling Less'
      files.each do |f|
        target_subdir = params[:target_subdir].nil? ? '' : "#{params[:target_subdir]}/"
        sh "#{command.join(' ')} #{f} #{target_dir}/#{target_subdir}#{Buildr::Util.relative_path(f, source_dir)[0...-5]}.css"
      end
      touch target_dir
    end

    project.assets.paths << project.file(target_dir => [compile_task])
    target_dir
  else
    nil
  end
end
