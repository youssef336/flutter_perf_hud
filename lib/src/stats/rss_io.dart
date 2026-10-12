import 'dart:io' show ProcessInfo;

/// Current resident set size of the process in bytes.
int? readCurrentRss() {
  try {
    return ProcessInfo.currentRss;
  } on Object {
    return null;
  }
}

/// Peak resident set size of the process in bytes.
int? readMaxRss() {
  try {
    return ProcessInfo.maxRss;
  } on Object {
    return null;
  }
}
