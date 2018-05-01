{
  config = {
    user = "andrei.volt@gmail.com";
    password = builtins.getEnv "PANDORA_PASSWORD";
    audio_quality = "high";
  };
}


