import Foundation

extension String {
    func levenshteinDistance(to other: String) -> Int {
        let m = self.count
        let n = other.count

        if m == 0 { return n }
        if n == 0 { return m }

        let selfChars = Array(self)
        let otherChars = Array(other)

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)

        for i in 0...m { matrix[i][0] = i }
        for j in 0...n { matrix[0][j] = j }

        for i in 1...m {
            for j in 1...n {
                let cost = selfChars[i - 1] == otherChars[j - 1] ? 0 : 1
                matrix[i][j] = Swift.min(
                    matrix[i - 1][j] + 1,
                    Swift.min(
                        matrix[i][j - 1] + 1,
                        matrix[i - 1][j - 1] + cost
                    )
                )
            }
        }

        return matrix[m][n]
    }

    func fuzzyMatches(_ other: String, maxDistance: Int = 2) -> Bool {
        lowercased().levenshteinDistance(to: other.lowercased()) <= maxDistance
    }
}
