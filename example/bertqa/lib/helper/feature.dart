class Feature {
  List<int> inputIds;
  List<int> inputMask;
  List<int> segmentIds;
  List<String> origTokens;
  Map<int, int> tokenToOrigMap;

  Feature(
      {required this.inputIds,
      required this.inputMask,
      required this.segmentIds,
      required this.origTokens,
      required this.tokenToOrigMap});
}
