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
- **Export:** float16-quantized TFLite (~6 MB), verified for exact
  prediction parity (argmax agreement) with the source Keras model.

## Experiment: hybrid cropping vs original images

Controlled comparison: same 110 images, `splits.csv` (MD5 f82f3699…), folds,
seeds (42 + fold), architecture and hyperparameters; only the images differ.
Cropped images: `dataset_cropped_matched/` (79 cropped, 31 unchanged;
`Kailasanathar_Temple_22.jpg` restored from the original because the crop step
produced no file). 16 cropped images have a shorter side < 150 px.
Outputs: `out_e60/` (baseline), `out_cropped_e60/` (cropped); `out_oof/` holds
out-of-fold probabilities. Final cropped model: 35 epochs (median CV best epoch).

| Metric               | Original      | Cropped       |
| -------------------- | ------------- | ------------- |
| CV accuracy          | 0.874 ± 0.071 | 0.925 ± 0.054 |
| CV macro-F1          | 0.858 ± 0.078 | 0.923 ± 0.055 |
| Test accuracy (n=16) | 0.875         | 0.875         |
| Test macro-F1        | 0.869         | 0.871         |

- CV: accuracy better in 3 folds, tied in 1, worse in 1. Per image: 9 fixed,
  4 broken (exact McNemar p ≈ 0.27, not significant).
- Test: both models make 2 errors on different images; no measurable difference.
- Visual check of 4 broken images: 1 plausible detail loss (durga_023),
  1 unchanged image (training variance), 2 likely noise.
- Background-confusion reduction is a hypothesis, not demonstrated.

### Unknown rejection (OOF, 94 known / 19 unknown × 5 fold models)

| Thr | Known correct+accepted (orig / crop) | Unknown rejected (orig / crop) |
| --- | ------------------------------------ | ------------------------------ |
| 0.6 | 0.723 / 0.840                        | 0.705 / 0.695                  |
| 0.7 | 0.628 / 0.755                        | 0.832 / 0.821                  |
| 0.8 | 0.479 / 0.564                        | 0.968 / 0.937                  |

Cropped model threshold: **0.7** (Youden J peak, chosen from OOF, not test).
Unknown set also guided the choice, so rejection rates are optimistic.

### TFLite (cropped)

6.05 MB; Keras–TFLite max prob diff 0.0095, argmax agreement 1.000,
TFLite test accuracy 0.875 (n=16). Not yet deployed to the app.

### Limitations

16 test images and 19 unknown images are too few for significance; the cropped
model is preliminary. Training used CPU on Colab (TF 2.21.0 / Keras 3.13.2);
baseline library versions are unknown.

## Repository structure

```
lib/
  main.dart                   App entry point
  camera_screen.dart          Live camera UI + prediction smoothing + overlay card
  sculpture_classifier.dart   TFLite inference wrapper
assets/
  sculpture_classifier.tflite   Exported model
  model_info.json               Labels, input spec, confidence threshold
  heritage.json                 Sculpture name/description/significance/mythology
training/                       (training pipeline scripts; add if not yet present)
  01_audit_and_split.py         Dataset audit + leakage-safe train/val/test split
  02_train.py                   Train (cross-validation or final) the classifier
  03_export_tflite.py           Export to TFLite, verify parity, calibrate threshold
android/, ios/, ...              Flutter platform folders
```

_The raw training dataset (hundreds of sculpture images) is not committed to
this repo — only the exported model and scripts._

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

## Running the Flutter app

```bash
flutter pub get
flutter run -d <device-id>
```

Requires a physical device with a camera (the `camera` plugin does not work
in most emulators). Grant the camera permission prompt on first launch.

The app runs a live camera preview, classifies a frame roughly every 700ms,
and smooths predictions over a 5-frame majority vote before showing an
overlay card. Predictions below the confidence threshold are treated as
"not recognised."

### Updating the model

1. Copy `out_e60/sculpture_classifier.tflite` and `out_e60/model_info.json`
   into `assets/`.
2. Edit `assets/heritage.json` with sculpture information (keys must match
   the labels in `model_info.json` exactly).
3. `flutter pub get && flutter run`

## Tech stack

- **Model training:** TensorFlow/Keras, scikit-learn (grouped CV splitting,
  logistic-regression baseline, metrics), MobileNetV3-Large (ImageNet
  pretrained).
- **App:** Flutter, `tflite_flutter`, `camera`.

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
- [x] GitHub repo set up
- [ ] Fix live-camera misclassification bias
- [ ] On-site phone photo validation at the temple
- [ ] Final heritage content for all five sculptures
