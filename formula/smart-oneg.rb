class SmartOneg < Formula
  desc "The Ultimate Shabbos & Yom Tov Smart Home Automation App"
  homepage "https://smartoneg.com"
  url "https://github.com/moshechaikin/smart-oneg/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5"
  license "ISC"

  depends_on "node@22"

  def install
    libexec.install Dir["*"]
    cd libexec do
      system "npm", "ci", "--omit=dev"
    end
    # launcher: pins node@22, defaults DATA_DIR to a persistent Homebrew var dir
    # (survives upgrades) unless the user overrides it
    (bin/"smart-oneg").write <<~SH
      #!/bin/bash
      export DATA_DIR="${DATA_DIR:-#{var}/smart-oneg}"
      exec "#{Formula["node@22"].opt_bin}/node" "#{libexec}/server/index.js" "$@"
    SH
  end

  def post_install
    (var/"smart-oneg").mkpath
  end

  # `brew services start smart-oneg` — launchd keeps it alive + starts at login
  service do
    run [opt_bin/"smart-oneg"]
    keep_alive true
    working_dir var/"smart-oneg"
    environment_variables DATA_DIR: var/"smart-oneg", PORT: "1836"
    log_path var/"log/smart-oneg.log"
    error_log_path var/"log/smart-oneg.log"
  end

  test do
    # server boots and the health endpoint answers, then we kill it
    port = "18360"
    pid = spawn({ "PORT" => port, "DATA_DIR" => testpath/"data" }, "#{bin}/smart-oneg")
    sleep 4
    assert_match "\"status\"", shell_output("curl -s http://127.0.0.1:#{port}/api/health")
  ensure
    Process.kill("TERM", pid) if pid
  end
end
