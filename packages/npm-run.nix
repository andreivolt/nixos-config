self: super: with super; {

npm-run = writeShellScriptBin "npm-run" ''
  package_name=$1
  executable_name=$2
  shift; shift
  args="$*"
  image_name=node.$package_name

  if [[ -z $(docker images -f reference=$image_name -q) ]]; then
    docker run -ti node sh -c "
      npm install -g $package_name"
    docker commit $(docker ps -lq) $image_name
  fi

  docker run -i \
    --net host \
    $image_name sh -c "
      $executable_name $args"'';
}
