import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

enum WorkCategory {
  agreementManagement,
  dispatchWork,
  protocol,
  otherWork,
  projectWork;

  String get label {
    switch (this) {
      case WorkCategory.agreementManagement:
        return AppStrings.categoryAgreement;
      case WorkCategory.dispatchWork:
        return AppStrings.categoryDispatch;
      case WorkCategory.protocol:
        return AppStrings.categoryProtocol;
      case WorkCategory.otherWork:
        return AppStrings.categoryOther;
      case WorkCategory.projectWork:
        return AppStrings.categoryProject;
    }
  }

  Color get color {
    switch (this) {
      case WorkCategory.agreementManagement:
        return AppColors.lightBlue;
      case WorkCategory.dispatchWork:
        return AppColors.mediumBlue;
      case WorkCategory.protocol:
        return AppColors.darkBlue;
      case WorkCategory.otherWork:
        return const Color(0xFF4A9BBF);
      case WorkCategory.projectWork:
        return const Color(0xFF2E7FA8);
    }
  }

  IconData get icon {
    switch (this) {
      case WorkCategory.agreementManagement:
        return Icons.handshake_outlined;
      case WorkCategory.dispatchWork:
        return Icons.flight_outlined;
      case WorkCategory.protocol:
        return Icons.people_outlined;
      case WorkCategory.otherWork:
        return Icons.folder_outlined;
      case WorkCategory.projectWork:
        return Icons.rocket_launch_outlined;
    }
  }
}

// 협약관리 하위분류
enum AgreementSubtype {
  newMou,
  newSea,
  renewMou,
  renewSea;

  String get label {
    switch (this) {
      case AgreementSubtype.newMou:
        return '신규 MoU';
      case AgreementSubtype.newSea:
        return '신규 SEA';
      case AgreementSubtype.renewMou:
        return '갱신 MoU';
      case AgreementSubtype.renewSea:
        return '갱신 SEA';
    }
  }
}

enum TaskStatus {
  pending,
  inProgress,
  completed;

  String get label {
    switch (this) {
      case TaskStatus.pending:
        return AppStrings.statusPending;
      case TaskStatus.inProgress:
        return AppStrings.statusInProgress;
      case TaskStatus.completed:
        return AppStrings.statusCompleted;
    }
  }

  Color get color {
    switch (this) {
      case TaskStatus.pending:
        return AppColors.statusPending;
      case TaskStatus.inProgress:
        return AppColors.statusInProgress;
      case TaskStatus.completed:
        return AppColors.statusCompleted;
    }
  }
}

enum TaskPriority {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case TaskPriority.low:
        return AppStrings.priorityLow;
      case TaskPriority.medium:
        return AppStrings.priorityMedium;
      case TaskPriority.high:
        return AppStrings.priorityHigh;
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return AppColors.priorityLow;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.high:
        return AppColors.priorityHigh;
    }
  }
}
