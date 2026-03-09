enum Lang { en, my }

class I18n {
  final Lang lang;
  I18n(this.lang);

  String get lunch => lang == Lang.my ? 'နေ့လယ် နာရီခေါင်း' : 'Lunch Bell';
  String get shift => lang == Lang.my ? 'လှည့်ပတ် အစားပြောင်း' : 'Shift Change';
  String get energy => lang == Lang.my ? 'ဓာတ်အား သတိပေး' : 'Energy Alarm';
  String get tornado => lang == Lang.my ? 'မုန်တိုင်း' : 'TORNADO';
}
