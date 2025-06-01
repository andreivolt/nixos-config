{
  python3,
  fetchFromGitHub,
  playwright-driver,
}:
python3.pkgs.buildPythonApplication rec {
  pname = "screenshot-tweet";
  version = "1.0";
  src = fetchFromGitHub {
    owner = "andreivolt";
    repo = "screenshot_tweet";
    rev = "105112db4d527fed223bbcc4a736dd75398e06cd";
    hash = "sha256-s+0Th3Wbm0YjJAZb2hXhSntAiF3xvWgYDNsmEIsSr2c=";
  };
  propagatedBuildInputs = with python3.pkgs; [
    playwright
  ];
  preBuild = ''
    cat > setup.py << EOF
    from setuptools import setup
    setup(
      name="${pname}",
      version="${version}",
      scripts=[
        'screenshot_tweet',
      ],
      install_requires=[
        'playwright',
      ],
      entry_points={
        'console_scripts': [
          'screenshot_tweet=screenshot_tweet:main'
        ]
      },
    )
    EOF
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp screenshot_tweet $out/bin
    chmod +x $out/bin/screenshot_tweet
  '';
  postInstall = ''
    wrapProgram $out/bin/screenshot_tweet \
      --set PLAYWRIGHT_BROWSERS_PATH "${playwright-driver.browsers.outPath}"
  '';
  doCheck = false;
}
