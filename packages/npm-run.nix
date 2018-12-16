self: super: with super; {

npm-run = writeShellScriptBin "npm-run" ''
  package_name=$1
  executable_name=$2
  shift; shift
  args="$*"
  image_name=node.$package_name

  run() {
    docker run -ti \
      --net host \
      $image_name sh -c "
        node_modules/.bin/$executable_name $args"
  }

  run || {
    if [[ -z $(docker images -f reference=$image_name -q) ]]; then
      docker run -ti node sh -c "
        npm install $package_name"
      docker commit $(docker ps -lq) $image_name
    fi
    run
  }
'';

}
