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
