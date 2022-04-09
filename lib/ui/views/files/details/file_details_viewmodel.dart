import 'package:easy_localization/easy_localization.dart';
import 'package:mobileraker/app/app_setup.locator.dart';
import 'package:mobileraker/app/app_setup.logger.dart';
import 'package:mobileraker/app/app_setup.router.dart';
import 'package:mobileraker/domain/hive/machine.dart';
import 'package:mobileraker/dto/files/gcode_file.dart';
import 'package:mobileraker/dto/machine/print_stats.dart';
import 'package:mobileraker/dto/machine/printer.dart';
import 'package:mobileraker/dto/server/klipper.dart';
import 'package:mobileraker/service/moonraker/klippy_service.dart';
import 'package:mobileraker/service/machine_service.dart';
import 'package:mobileraker/service/moonraker/printer_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

const String _ServerStreamKey = 'server';
const String _PrinterStreamKey = 'printer';

class FileDetailsViewModel extends MultipleStreamViewModel {
  final _logger = getLogger('FileDetailsViewModel');
  final _dialogService = locator<DialogService>();
  final _snackBarService = locator<SnackbarService>();
  final _navigationService = locator<NavigationService>();
  final _machineService = locator<MachineService>();

  Machine? get _machine =>
      _machineService.selectedMachine.valueOrNull;

  PrinterService? get _printerService => _machine?.printerService;

  KlippyService? get _klippyService => _machine?.klippyService;

  final GCodeFile _file;

  FileDetailsViewModel(this._file);

  @override
  Map<String, StreamData> get streamsMap => {
        if (_printerService != null)
          _PrinterStreamKey:
              StreamData<Printer>(_printerService!.printerStream),
        if (_klippyService != null)
          _ServerStreamKey:
              StreamData<KlipperInstance>(_klippyService!.klipperStream),
      };

  bool get isServerAvailable => dataReady(_ServerStreamKey);

  KlipperInstance get server => dataMap![_ServerStreamKey];

  bool get isPrinterAvailable => dataReady(_PrinterStreamKey);

  Printer get printer => dataMap![_PrinterStreamKey];

  onStartPrintTap() {
    _printerService?.startPrintFile(_file);
    _navigationService.clearStackAndShow(Routes.dashboardView);
  }

  bool get canStartPrint {
    if (!isServerAvailable ||
        !isPrinterAvailable ||
        server.klippyState != KlipperState.ready)
      return false;
    else
      return (printer.print.state == PrintState.complete ||
          printer.print.state == PrintState.standby ||
          printer.print.state == PrintState.error);
  }

  String? get curPathToPrinterUrl {
    if (_machine != null) {
      return '${_machine!.httpUrl}/server/files';
    }
    return null;
  }

  String get formattedLastPrinted {
    return DateFormat.yMMMd().add_Hm().format(_file.lastPrintDate!);
  }

  String get formattedLastModified {
    return DateFormat.yMMMd().add_Hm().format(_file.modifiedDate!);
  }

  String get potentialEta {
    if (_file.estimatedTime == null) return tr('general.unknown');
    var eta = DateTime.now()
        .add(Duration(seconds: _file.estimatedTime!.toInt()))
        .toLocal();
    return DateFormat.MMMEd().add_Hm().format(eta);
  }

  String get usedSlicerAndVersion {
    String ukwn = tr('general.unknown');
    if (_file.slicerVersion == null) return _file.slicer ?? ukwn;

    return '${_file.slicer ?? ukwn} (v${_file.slicerVersion})';
  }

  bool get preHeatAvailable => _file.firstLayerTempBed != null;

  preHeatPrinter() {
    _dialogService
        .showConfirmationDialog(
      title: "Preheat?",
      description: 'Target Temperatures\n'
          'Extruder: 170°C\n'
          'Bed: ${_file.firstLayerTempBed?.toStringAsFixed(0)}°C',
      confirmationTitle: "Preheat",
    )
        .then((dialogResponse) {
      if (dialogResponse?.confirmed ?? false) {
        _printerService?.setTemperature('extruder', 170);
        _printerService?.setTemperature(
            'heater_bed', (_file.firstLayerTempBed ?? 60.0).toInt());
        _snackBarService.showSnackbar(
            title: 'Confirmed',
            message:
                'Preheating Extruder: 170°C, Bed: ${_file.firstLayerTempBed?.toStringAsFixed(0)}°C');
      }
    });
  }
}
