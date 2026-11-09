import hashlib
import importlib.util
import tempfile
import subprocess
import sys
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location('content_check', Path(__file__).resolve().parents[1] / 'tools/check_content.py')
content = importlib.util.module_from_spec(spec)
spec.loader.exec_module(content)

class PublicationBoundary(unittest.TestCase):
    def test_private_formats_and_extensionless_executable_are_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            for name, data in {'game.nup': b'dump', 'prod.keys': b'placeholder', 'effect.metallib': b'shader', 'main': b'NSO0payload', 'progress.sav': b'save'}.items():
                (root / name).write_bytes(data)
            errors, _ = content.check(root, list(content.publication_files(root)), {})
            self.assertEqual(len(errors), 5)

    def test_only_exact_synthetic_fixture_bytes_are_allowed(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d); p = root / 'sample.nso'; p.write_bytes(b'NSO0fake')
            allowed = {'sample.nso': hashlib.sha256(p.read_bytes()).hexdigest()}
            self.assertFalse(content.check(root, [p], allowed)[0])
            p.write_bytes(b'NSO0different')
            self.assertTrue(content.check(root, [p], allowed)[0])

    def test_signed_app_and_release_outputs_cannot_be_nested_in_source_package(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d); app = root / 'PackedGame.app'; app.mkdir(); (app / 'main').write_text('private')
            dist = root / 'dist'; dist.mkdir(); (dist / 'game.nup').write_text('private output, never packaged')
            paths = list(content.publication_files(root))
            self.assertNotIn(dist / 'game.nup', paths)
            self.assertTrue(content.check(root, paths, {})[0])

    def test_staged_bytes_are_checked_even_when_working_tree_was_replaced(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            subprocess.run(['git', 'init', '-q', str(root)], check=True)
            p = root / 'main'; p.write_bytes(b'NSO0private')
            subprocess.run(['git', '-C', str(root), 'add', 'main'], check=True)
            p.write_text('innocent working copy')
            result = subprocess.run([sys.executable, str(content.ROOT / 'tools/check_content.py'), '--root', str(root), '--staged'], capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('staged:', result.stdout)

if __name__ == '__main__':
    unittest.main()
