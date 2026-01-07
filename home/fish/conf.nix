{
  config,
  pkgs,
  uname,
  ...
}:

{
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      function __fix_typos_preexec --on-event fish_preexec
        set cmd (commandline)

        if string match -rq '\b(udpa|upda|udpate)\b' -- $cmd
          set cmd (string replace -ra '\budpa' upda $cmd)
          commandline -r $cmd
        end
      end
    '';

    shellAbbrs = {
      abreviat = "abbreviat";
      accomadat = "accommodat";
      accomodat = "accommodat";
      acheiv = "achiev";
      achievment = "achievement";
      acquaintence = "acquaintance";
      adquir = "acquir";
      aquisition = "acquisition";
      agravat = "aggravat";
      allign = "align";
      ameria = "America";
      archaelog = "archaeolog";
      archtyp = "archetyp";
      archetect = "architect";
      arguement = "argument";
      assasin = "assassin";
      asociat = "associat";
      assymetr = "asymmet";
      atempt = "attempt";
      atribut = "attribut";
      avaialb = "availab";
      comision = "commission";
      contien = "conscien";
      critisi = "critici";
      crticis = "criticis";
      critiz = "criticiz";
      desicant = "desiccant";
      desicat = "desiccat";
      develope = "develop";
      dissapoint = "disappoint";
      divsion = "division";
      dcument = "document";
      embarass = "embarrass";
      emminent = "eminent";
      empahs = "emphas";
      enlargment = "enlargement";
      envirom = "environm";
      enviorment = "environment";
      excede = "exceed";
      exilerat = "exhilarat";
      extraterrestial = "extraterrestrial";
      faciliat = "facilitat";
      garantee = "guaranteed";
      guerrila = "guerrilla";
      guidlin = "guidelin";
      girat = "gyrat";
    };
  };

}
