# Kailasanathar AR — Sculpture Recognition

AR-based recognition and interpretation of sculptures at the Kailasanathar
Temple, Kanchipuram. Point a phone camera at a supported sculpture and the
app recognizes it and displays its name, description, historical
significance, and mythological background.

## Pipeline

```
Image Dataset → Preprocessing → CV Model (MobileNetV3) → Sculpture Recognition
→ Heritage Database (JSON) → Flutter App (camera + TFLite)
```

## Supported classes

| Class                    | Images (distinct) |
| ------------------------ | ----------------- |
| Dakshinamurthy           | 16                |
| Dancing Shiva (Nataraja) | 24                |
| Durga                    | 23                |
| Nandi                    | 23                |
| Shiva–Parvati            | 19                |

Images are sourced only from the Kailasanathar Temple, Kanchipuram — no
images from other temples are used, even of the same deity.

## Model and results

- **Architecture:** frozen MobileNetV3-Large (ImageNet) backbone + a trained
  dense head, with augmentation and preprocessing built into the model.
- **Evaluation:** 5-fold grouped, stratified cross-validation (near-duplicate
  images grouped so they can't leak across folds), plus a single untouched
  held-out test set.
- **Cross-validation:** 0.874 ± 0.071 accuracy, 0.858 macro-F1.
- **Held-out test (16 images, touched once):** 0.875 accuracy, 0.869 macro-F1.
- **Baseline comparison:** a frozen-embedding + logistic-regression classifier
  was evaluated on the same folds for comparison (0.863 CV accuracy); the
  trained head was chosen for deployment for its built-in augmentation
  robustness to camera conditions.
- **Known weak spots:** Dancing Shiva and Shiva–Parvati are the least
  reliable classes; Nandi is the most reliable.

## Repository structure

```
scripts/
  01_audit_and_split.py   Dataset audit + leakage-safe train/val/test split
  02_train.py              Train (cross-validation or final) the classifier
  03_export_tflite.py      Export to TFLite, verify parity, calibrate threshold
lib/
  main.dart                App entry point
  camera_screen.dart        Live camera UI + prediction smoothing + overlay card
  sculpture_classifier.dart TFLite inference wrapper
assets/
  sculpture_classifier.tflite  Exported model
  model_info.json              Labels, input spec, confidence threshold
  heritage.json                 Sculpture name/description/significance/mythology
```

## Training pipeline (Python / Google Colab)

```bash
pip install pillow imagehash pandas scikit-learn tensorflow

# 1. Audit the dataset and create a leakage-safe split
python 01_audit_and_split.py --root dataset --out splits.csv

# 2. Cross-validate, then train the final model
python 02_train.py --mode cv    --root dataset --splits splits.csv --outdir out_e60 --epochs 60
python 02_train.py --mode final --root dataset --splits splits.csv --outdir out_e60 --epochs 60

# 3. Export to TFLite and calibrate the "not recognised" threshold
python 03_export_tflite.py --outdir out_e60 --root dataset --splits splits.csv --unknown_dir unknown
```

## Flutter app

1. Copy `out_e60/sculpture_classifier.tflite` and `out_e60/model_info.json`
   into `assets/`.
2. Edit `assets/heritage.json` with the real sculpture information (keys
   must match the labels in `model_info.json` exactly).
3. `flutter pub get`
4. `flutter run`

The app runs a live camera preview, classifies a frame roughly every 700ms,
and smooths predictions over a 5-frame majority vote before showing an
overlay card. Predictions below the confidence threshold are treated as
"not recognised."

## Known limitations

- **Small dataset** (16–24 images per class), built entirely from online
  photos — no on-site phone photos yet. This creates a domain-shift gap
  between training images (clean, cropped, web-sourced) and live phone
  camera frames (cluttered backgrounds, variable lighting, motion blur).
- Currently under investigation: live predictions are biased toward a
  single class (Durga) more often than cross-validation results would
  suggest. Likely causes being checked: tighter cropping during live
  inference, EXIF orientation handling, and confidence threshold tuning.
- The ~16-image held-out test set is too small for precise per-class
  accuracy; cross-validation is the more reliable estimate.

## Status

- [x] Dataset collection and leakage-safe split
- [x] Model training and cross-validation
- [x] TFLite export and threshold calibration
- [x] Flutter camera app with live inference and overlay
- [ ] Fix live-camera misclassification bias
- [ ] On-site phone photo validation at the temple
- [ ] Final heritage content for all five sculptures
