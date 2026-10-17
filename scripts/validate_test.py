"""Tests for the literal SDK version check in validate.py."""
import unittest

from validate import version_findings


class VersionFindingsTest(unittest.TestCase):
    def test_flags_whisperr_sdk_versions(self):
        for text in (
            "needs @whisperr/web 0.4.0 or later",
            "Swift package from v0.6.0",
            "# Swift / iOS (whisperr-swift 0.4+)",
            "It needs `@whisperr/react-native` 0.5 or later.",
            "Flutter whisperr 0.7.0",
        ):
            with self.subTest(text=text):
                self.assertEqual(len(version_findings(text)), 1)

    def test_reports_the_line(self):
        self.assertEqual(version_findings("intro\n\nweb 0.4.0"), [(3, "0.4.0")])

    def test_allows_other_products_and_urls(self):
        for text in (
            "Apple App Review guideline 4.5.4 needs consent",
            "# Flutter (Flutter 3.19+)",
            "`<pm> add @whisperr/node@<version>` (Node 18+).",
            "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json",
            "https://docs.whisperr.net/sdk-versions.json",
        ):
            with self.subTest(text=text):
                self.assertEqual(version_findings(text), [])


if __name__ == "__main__":
    unittest.main()
