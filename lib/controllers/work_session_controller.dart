enum WorkSessionStatus { idle, running, paused, stopped }

class WorkSessionController {
  WorkSessionStatus _status = WorkSessionStatus.idle;
  bool _isSaveConfirmed = false;

  WorkSessionStatus get status => _status;
  bool get isSaveConfirmed => _isSaveConfirmed;
  bool get hasSession => _status != WorkSessionStatus.idle;
  bool get hasUnsavedSession => hasSession && !_isSaveConfirmed;

  bool start() {
    if (_status != WorkSessionStatus.idle) return false;

    _status = WorkSessionStatus.running;
    _isSaveConfirmed = false;
    return true;
  }

  bool pause() {
    if (_status != WorkSessionStatus.running) return false;

    _status = WorkSessionStatus.paused;
    return true;
  }

  bool resume() {
    if (_status != WorkSessionStatus.paused) return false;

    _status = WorkSessionStatus.running;
    return true;
  }

  bool stop() {
    if (_status != WorkSessionStatus.running &&
        _status != WorkSessionStatus.paused) {
      return false;
    }

    _status = WorkSessionStatus.stopped;
    return true;
  }

  bool confirmSaved() {
    if (_status != WorkSessionStatus.stopped || _isSaveConfirmed) return false;

    _isSaveConfirmed = true;
    return true;
  }

  bool prepareForNextSession() {
    if (_status != WorkSessionStatus.stopped || !_isSaveConfirmed) return false;

    _status = WorkSessionStatus.idle;
    return true;
  }

  bool rollbackUnsaved() {
    if (!hasUnsavedSession) return false;

    _status = WorkSessionStatus.idle;
    _isSaveConfirmed = false;
    return true;
  }
}
