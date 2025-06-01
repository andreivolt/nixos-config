{
  pkgs,
  config,
  ...
}: {
  boot.kernelModules = ["v4l2loopback"];

  boot.extraModulePackages = with config.boot.kernelPackages; [v4l2loopback.out];

  boot.extraModprobeConfig = "options v4l2loopback exclusive_caps=1"; # Chrome needs exclusive_caps=1

  environment.systemPackages = [pkgs.linuxPackages.v4l2loopback];

  # https://gist.github.com/ioquatix/18720c80a7f7eb997c19eef8afd6901e # TODO
}
