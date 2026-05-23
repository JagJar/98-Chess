import SwiftUI

struct MoveHistoryView: View {
    let sanMoves: [String]

    var body: some View {
        Group {
            if pairs.isEmpty {
                HStack {
                    Text("No moves yet.")
                        .font(.system(size: 11))
                        .foregroundStyle(Win98.Palette.shadow)
                    Spacer()
                }
                .padding(6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        VStack(alignment: .leading, spacing: 1) {
                            ForEach(pairs.indices, id: \.self) { idx in
                                HStack(spacing: 6) {
                                    Text("\(idx + 1).")
                                        .frame(width: 24, alignment: .trailing)
                                        .foregroundStyle(Win98.Palette.shadow)
                                    Text(pairs[idx].white)
                                        .frame(width: 56, alignment: .leading)
                                    Text(pairs[idx].black ?? "")
                                        .frame(width: 56, alignment: .leading)
                                    Spacer(minLength: 0)
                                }
                                .font(.system(size: 11).monospaced())
                                .foregroundStyle(Win98.Palette.text)
                                .id(idx)
                            }
                        }
                        .padding(4)
                    }
                    .scrollIndicators(.hidden)
                    .onChange(of: sanMoves.count) { _, _ in
                        if !pairs.isEmpty {
                            proxy.scrollTo(pairs.count - 1, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Win98.Palette.face)
        .win98Bevel(.inset)
    }

    private var pairs: [(white: String, black: String?)] {
        var out: [(String, String?)] = []
        var idx = 0
        while idx < sanMoves.count {
            let w = sanMoves[idx]
            let b = idx + 1 < sanMoves.count ? sanMoves[idx + 1] : nil
            out.append((w, b))
            idx += 2
        }
        return out
    }
}
