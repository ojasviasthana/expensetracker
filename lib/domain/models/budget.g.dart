// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Budget _$BudgetFromJson(Map<String, dynamic> json) => _Budget(
  dailyLimit: (json['dailyLimit'] as num).toDouble(),
  monthlyLimit: (json['monthlyLimit'] as num?)?.toDouble(),
);

Map<String, dynamic> _$BudgetToJson(_Budget instance) => <String, dynamic>{
  'dailyLimit': instance.dailyLimit,
  'monthlyLimit': instance.monthlyLimit,
};
