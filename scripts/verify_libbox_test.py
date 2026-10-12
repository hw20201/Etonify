"""Verify fork provenance against committed core Git objects."""
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import verify_libbox

PIN = {"repository":"https://github.com/yamixdev/sing-tun.git", "commit":"1"*40,
       "upstream_commit":"5c2edb183cc92eb190d41c04dedfa5519ca3e78c",
       "module_version":"v0.9.7-0.20261009022811-5c2edb183cc9"}


class SingTunProvenanceTests(unittest.TestCase):
    def test_real_fresh_checkout_initializes_recorded_git_objects(self):
        source_core=verify_libbox.CORE_PATH
        with tempfile.TemporaryDirectory() as tmp:
            checkout=Path(tmp)/"client"
            subprocess.check_output(["git","clone","--shared",str(verify_libbox.ROOT),str(checkout)],stderr=subprocess.STDOUT)
            libs=checkout/"android/app/libs"
            with patch.multiple(verify_libbox,ROOT=checkout,CORE_PATH=checkout/"etonify-core",LIBS=libs,
                                AAR=libs/"libbox.aar",SOURCES=libs/"libbox-sources.jar",HASH_FILE=libs/"libbox.sha256",PROVENANCE_FILE=libs/"libbox.provenance.json"):
                with self.assertRaises(subprocess.CalledProcessError): verify_libbox.main()
                subprocess.check_output(["git","-c","protocol.file.allow=always","-c",
                    "submodule.etonify-core.url="+str(source_core),
                    "submodule","update","--init","--depth","1","--","etonify-core"],cwd=checkout,stderr=subprocess.STDOUT)
                verify_libbox.main()
    def test_verifier_workflows_initialize_recorded_core_first(self):
        root=Path(__file__).resolve().parents[1]
        for name in ("ci.yml","android-release.yml","codeql.yml"):
            text=(root/".github/workflows"/name).read_text()
            with self.subTest(workflow=name):
                command="git submodule update --init --depth 1 -- etonify-core"
                self.assertIn(command,text)
                self.assertLess(text.index(command),text.index("python3 scripts/verify_libbox.py"))
    def test_bundled_artifact_against_its_recorded_checkout(self):
        provenance=json.loads(verify_libbox.PROVENANCE_FILE.read_text())
        with tempfile.TemporaryDirectory() as tmp:
            checkout=Path(tmp)/"recorded-core"
            subprocess.check_output(["git","clone","--shared","--no-checkout",str(verify_libbox.CORE_PATH),str(checkout)],stderr=subprocess.STDOUT)
            subprocess.check_output(["git","checkout","--detach",provenance["source_commit"]],cwd=checkout,stderr=subprocess.STDOUT)
            with patch.object(verify_libbox,"CORE_PATH",checkout): verify_libbox.main()
    def test_both_producers_use_checked_pin_schema(self):
        root=Path(__file__).resolve().parents[1]
        for path in (root/".github/workflows/sync-etonify-core.yml",root/"etonify-core/.github/workflows/etonify-libbox.yml"):
            if path.parent.parent.parent.name == "etonify-core" and not (root/"etonify-core/release/SING_TUN_PIN.json").is_file():
                continue # Delivered legacy core does not produce fork metadata.
            text=path.read_text()
            with self.subTest(path=path.name):
                self.assertIn("release/sing_tun_pin.py",text)
                self.assertIn("--strict",text)
                for key in PIN: self.assertIn("sing_tun_"+key,text)
    def test_correct_four_fields(self):
        verify_libbox.verify_sing_tun_provenance({"sing_tun_"+k:v for k,v in PIN.items()}, PIN)

    def test_missing_old_sha_or_upstream_url_rejected(self):
        for key,value in (("commit","2"*40),("repository","https://github.com/SagerNet/sing-tun.git"),
                          ("upstream_commit","3"*40),("module_version","v0.0.0"),("commit",None)):
            p={"sing_tun_"+k:v for k,v in PIN.items()}
            if value is None: del p["sing_tun_"+key]
            else: p["sing_tun_"+key]=value
            with self.subTest(key=key,value=value), self.assertRaises(RuntimeError):
                verify_libbox.verify_sing_tun_provenance(p,PIN)

    def test_legacy_without_nested_pin_is_accepted(self):
        verify_libbox.verify_sing_tun_provenance({"etonify_version":"v1.15.0-alpha.10-etonify.2"},None)

    def test_expected_pin_uses_committed_tree_without_initialized_child(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp); (root/"release").mkdir()
            def git(*args): return subprocess.check_output(["git",*args],cwd=root,text=True,stderr=subprocess.STDOUT).strip()
            git("init"); git("config","user.name","Fixture"); git("config","user.email","fixture@example.invalid")
            (root/"release/SING_TUN_PIN.json").write_text(json.dumps(PIN))
            git("add","release/SING_TUN_PIN.json")
            git("update-index","--add","--cacheinfo",f"160000,{PIN['commit']},third_party/sing-tun")
            git("commit","-m","pin"); commit=git("rev-parse","HEAD")
            (root/"release/SING_TUN_PIN.json").write_text(json.dumps({**PIN,"commit":"2"*40}))
            self.assertFalse((root/"third_party/sing-tun").exists())
            self.assertEqual(PIN,verify_libbox.expected_sing_tun_pin(root,commit))
            git("add","release/SING_TUN_PIN.json"); git("commit","-m","wrong manifest")
            with self.assertRaises(RuntimeError): verify_libbox.expected_sing_tun_pin(root,git("rev-parse","HEAD"))
            git("rm","release/SING_TUN_PIN.json"); git("update-index","--force-remove","third_party/sing-tun")
            git("commit","-m","legacy")
            self.assertIsNone(verify_libbox.expected_sing_tun_pin(root,git("rev-parse","HEAD")))


if __name__=="__main__": unittest.main()
