import json
import unittest

from services.emr.jobs.streaming_classification.src.pipeline import _stub_classification, parse_record


class ParseRecordTests(unittest.TestCase):
    def test_parse_record_success(self):
        raw = json.dumps(
            {
                "jobId": "job-1",
                "clientId": "client-1",
                "imageKey": "galaxies/a.jpg",
            }
        )
        payload = parse_record(raw)
        self.assertEqual(payload["jobId"], "job-1")
        self.assertEqual(payload["clientId"], "client-1")
        self.assertEqual(payload["imageKey"], "galaxies/a.jpg")

    def test_parse_record_missing_fields(self):
        raw = json.dumps({"jobId": "job-1"})
        with self.assertRaises(ValueError):
            parse_record(raw)

    def test_stub_classification_is_deterministic(self):
        payload = {
            "jobId": "job-1",
            "clientId": "client-1",
            "imageKey": "galaxies/a.jpg",
        }
        result1 = _stub_classification(payload)
        result2 = _stub_classification(payload)

        self.assertEqual(result1, result2)
        self.assertIn(result1["label"], ["spiral", "elliptical"])
        self.assertGreaterEqual(result1["confidence"], 0.5)
        self.assertLessEqual(result1["confidence"], 0.995)


if __name__ == "__main__":
    unittest.main()
