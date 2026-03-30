{ pkgs, ... }:
{
  tts-server = {
    description = "Local espeak TTS server";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python3 " + ./main.py;
      Restart = "always";
    };
  };
}
