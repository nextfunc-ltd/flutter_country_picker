import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'country.dart';
import 'res/country_codes.dart';
import 'utils.dart';

class CountryListView extends StatefulWidget {
  /// Called when a country is select.
  ///
  /// The country picker passes the new value to the callback.
  final ValueChanged<Country> onSelect;
  /// An optional [showPhoneCode] argument can be used to show phone code.
  final bool showPhoneCode;

  final String initCountrySelected;

  /// An optional [exclude] argument can be used to exclude(remove) one ore more
  /// country from the countries list. It takes a list of country code(iso2).
  /// Note: Can't provide both [exclude] and [countryFilter]
  final List<String>? exclude;

  /// An optional [countryFilter] argument can be used to filter the
  /// list of countries. It takes a list of country code(iso2).
  /// Note: Can't provide both [countryFilter] and [exclude]
  final List<String>? countryFilter;

  /// An optional argument for customizing the
  /// country list bottom sheet.
  final CountryListThemeData? countryListTheme;

  /// An optional argument for initially expanding virtual keyboard
  final bool searchAutofocus;

  const CountryListView({
    Key? key,
    required this.onSelect,
    this.exclude,
    this.countryFilter,
    this.initCountrySelected = '',
    this.showPhoneCode = false,
    this.countryListTheme,
    this.searchAutofocus = false,
  })  : assert(exclude == null || countryFilter == null,
            'Cannot provide both exclude and countryFilter'),
        super(key: key);

  @override
  _CountryListViewState createState() => _CountryListViewState();
}

class _CountryListViewState extends State<CountryListView> {
  late List<Country> _countryList;
  late List<Country> _filteredList;
  late TextEditingController _searchController;
  late bool _searchAutofocus;
  final ScrollController _scrollController = ScrollController();
  int position = -1;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _countryList =
        countryCodes.map((country) => Country.from(json: country)).toList();
    if(widget.initCountrySelected != ''){
      for(int i = 0 ; i < _countryList.length; i++){
        if(_countryList[i].displayNameNoCountryCode.contains(widget.initCountrySelected)){
          position = i;
          break;
        }
      }
    }
    //Remove duplicates country if not use phone code
    if (!widget.showPhoneCode) {
      final ids = _countryList.map((e) => e.countryCode).toSet();
      _countryList.retainWhere((country) => ids.remove(country.countryCode));
    }

    if (widget.exclude != null) {
      _countryList.removeWhere(
          (element) => widget.exclude!.contains(element.countryCode));
    }
    if (widget.countryFilter != null) {
      _countryList.removeWhere(
          (element) => !widget.countryFilter!.contains(element.countryCode));
    }

    _filteredList = <Country>[];
    _filteredList.addAll(_countryList);

    _searchAutofocus = widget.searchAutofocus;
    onWidgetBuildDone(_autoScroll);
  }

  @override
  Widget build(BuildContext context) {
    final String searchLabel =
        CountryLocalizations.of(context)?.countryName(countryCode: 'search') ??
            'Search';

    return Column(
      children: <Widget>[
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          // child: TextField(
          //   autofocus: _searchAutofocus,
          //   controller: _searchController,
          //   decoration: widget.countryListTheme?.inputDecoration ??
          //       InputDecoration(
          //         labelText: searchLabel,
          //         hintText: searchLabel,
          //         prefixIcon: const Icon(Icons.search),
          //         border: OutlineInputBorder(
          //           borderSide: BorderSide(
          //             color: const Color(0xFF8C98A8).withOpacity(0.2),
          //           ),
          //         ),
          //       ),
          //   onChanged: _filterSearchResults,
          // ),
            child: Container(
              height: 40.0,
              child: TextField(
                autofocus: _searchAutofocus,
                controller: _searchController,
                onChanged: _filterSearchResults,
                style: TextStyle(fontSize: 14.0, color: Color(0xff3D4257)),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color(0xffF7F8FB),
                  hintText: searchLabel,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Image.asset(
                      "assets/ic_search.png",
                      package: "country_picker",
                      // color: AppColors.jetGreen,
                    ),
                  ),
                  hintStyle: TextStyle(fontSize: 14.0, color: Color(0xff9FA5B0)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xffF7F8FB),
                    ),
                  ),
                  contentPadding: const EdgeInsets.only(right: 20),
                  prefixIconConstraints: BoxConstraints(
                    minHeight: 16.0,
                    minWidth: 16.0,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xffF7F8FB)),
                  ),
                ),
              ),
            )
        ),
        Expanded(
          child:  ListView.builder(
              controller: _scrollController,
            itemCount: _filteredList.length,
              itemBuilder: (BuildContext context, int index){
            return _listRow(_filteredList[index], index);
          }),
        ),
      ],
    );
  }

  Widget _listRow(Country country, int index) {
    final TextStyle _textStyle =
        widget.countryListTheme?.textStyle ?? _defaultTextStyle;

    final bool isRtl = Directionality.of(context) == TextDirection.rtl;

    return Material(
      // Add Material Widget with transparent color
      // so the ripple effect of InkWell will show on tap
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          country.nameLocalized = CountryLocalizations.of(context)
              ?.countryName(countryCode: country.countryCode)
              ?.replaceAll(RegExp(r"\s+"), " ");
          widget.onSelect(country);
          setState(() {
            _countryList.forEach((element) => element.isSelected = false);
            _countryList[index].isSelected = true;
          });          Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: Row(
            children: <Widget>[
              const SizedBox(width: 20),
              SizedBox(
                // the conditional 50 prevents irregularities caused by the flags in RTL mode
                width: isRtl ? 50 : null,
                child: Text(
                  Utils.countryCodeToEmoji(country.countryCode),
                  style: TextStyle(
                    fontSize: widget.countryListTheme?.flagSize ?? 25,
                  ),
                ),
              ),
              if (widget.showPhoneCode) ...[
                const SizedBox(width: 15),
                SizedBox(
                  width: 45,
                  child: Text(
                    '${isRtl ? '' : '+'}${country.phoneCode}${isRtl ? '+' : ''}',
                    style: _textStyle,
                  ),
                ),
                const SizedBox(width: 5),
              ] else
                const SizedBox(width: 15),
              Expanded(
                child: Text(
                  CountryLocalizations.of(context)
                          ?.countryName(countryCode: country.countryCode)
                          ?.replaceAll(RegExp(r"\s+"), " ") ??
                      country.name,
                  style: _textStyle,
                ),
              ),
              Visibility(
                visible: position == index,
                  child: Icon(Icons.check, color: Color(0xff0A84FF),)),
              const SizedBox(width: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _filterSearchResults(String query) {
    List<Country> _searchResult = <Country>[];
    final CountryLocalizations? localizations =
        CountryLocalizations.of(context);

    if (query.isEmpty) {
      _searchResult.addAll(_countryList);
    } else {
      _searchResult = _countryList
          .where((c) => c.startsWith(query, localizations))
          .toList();
      _scrollController.animateTo(0, duration: new Duration(seconds: 2), curve: Curves.ease);
    }

    setState(() => _filteredList = _searchResult);
  }

  get _defaultTextStyle => const TextStyle(fontSize: 16);

  double getWidgetHeight(GlobalKey key) {
    final RenderBox renderBoxRed =
    key.currentContext!.findRenderObject() as RenderBox;
    return renderBoxRed.size.height;
  }

  void onWidgetBuildDone(Function function) {
    SchedulerBinding.instance!.addPostFrameCallback((_) {
      function();
    });
  }

  void _autoScroll() {
    if (position != -1) {
      _scrollController.animateTo(position * 43, duration: new Duration(seconds: 2), curve: Curves.ease);
    }
  }
}
