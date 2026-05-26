// leroyApp.swift - COMPLETE FILE WITH SWIFTDATA

import SwiftUI
import SwiftData
internal import Combine

@main
struct LeroyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: PlayerScore.self)
    }
}

// MARK: - Color Extensions
extension Color {
    static let appBackground = Color(red: 0.1, green: 0.1, blue: 0.15)
    static let appAccent = Color(red: 0.3, green: 0.6, blue: 1.0)
    static let appSecondary = Color(red: 0.8, green: 0.4, blue: 0.9)
}

// MARK: - SwiftData Model
@Model
class PlayerScore {
    var id: UUID
    var name: String
    var category: String
    var score: Int
    var date: Date
    
    init(id: UUID = UUID(), name: String, category: String, score: Int, date: Date = Date()) {
        self.id = id
        self.name = name
        self.category = category
        self.score = score
        self.date = date
    }
}

// MARK: - REST API #1: Random Word API with Category Support
class WordAPIService {
    // Category-specific word lists as backup
    static let categoryWords: [String: [String]] = [
        "Animals": ["elephant", "giraffe", "penguin", "dolphin", "butterfly", "kangaroo", "rabbit", "turtle", "tiger", "monkey"],
        "Food": ["pizza", "banana", "chocolate", "sandwich", "cookie", "burger", "pasta", "salad", "orange", "strawberry"],
        "Sports": ["basketball", "football", "baseball", "tennis", "swimming", "soccer", "hockey", "volleyball", "boxing", "running"],
        "Nature": ["mountain", "ocean", "forest", "desert", "river", "volcano", "beach", "valley", "meadow", "canyon"]
    ]
    
    static func fetchWords(category: String, completion: @escaping ([String]) -> Void) {
        // For simplicity and reliability, we'll use our word lists
        // This ensures the game always works
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let words = categoryWords[category] {
                let selectedWords = Array(words.shuffled().prefix(4))
                completion(selectedWords)
            } else {
                // Fallback to random words from API
                fetchRandomWords(completion: completion)
            }
        }
    }
    
    private static func fetchRandomWords(completion: @escaping ([String]) -> Void) {
        let urlString = "https://random-word-api.herokuapp.com/word?number=4"
        
        guard let url = URL(string: urlString) else {
            completion(["apple", "house", "water", "book"])
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    completion(["apple", "house", "water", "book"])
                }
                return
            }
            
            do {
                let words = try JSONDecoder().decode([String].self, from: data)
                DispatchQueue.main.async {
                    completion(words)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(["apple", "house", "water", "book"])
                }
            }
        }.resume()
    }
}

// MARK: - REST API #2: Dictionary API for Definitions
struct DictionaryResponse: Codable {
    let meanings: [Meaning]
}

struct Meaning: Codable {
    let definitions: [Definition]
}

struct Definition: Codable {
    let definition: String
}

class DictionaryAPIService {
    static func fetchDefinition(for word: String, completion: @escaping (String) -> Void) {
        let cleanWord = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let urlString = "https://api.dictionaryapi.dev/api/v2/entries/en/\(cleanWord)"
        
        guard let url = URL(string: urlString) else {
            completion(getBackupHint(for: cleanWord))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    completion(getBackupHint(for: cleanWord))
                }
                return
            }
            
            do {
                let responses = try JSONDecoder().decode([DictionaryResponse].self, from: data)
                if let firstDef = responses.first?.meanings.first?.definitions.first?.definition {
                    DispatchQueue.main.async {
                        completion(firstDef)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(getBackupHint(for: cleanWord))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(getBackupHint(for: cleanWord))
                }
            }
        }.resume()
    }
    
    private static func getBackupHint(for word: String) -> String {
        let hints: [String: String] = [
            "elephant": "A very large gray animal with a trunk and tusks",
            "giraffe": "A tall African animal with a very long neck and legs",
            "penguin": "A black and white bird that swims but cannot fly",
            "dolphin": "A smart sea animal that looks like a large fish",
            "butterfly": "A colorful insect with large wings",
            "kangaroo": "An Australian animal that hops and carries babies in a pouch",
            "rabbit": "A small furry animal with long ears that hops",
            "turtle": "A slow animal with a hard shell on its back",
            "tiger": "A large wild cat with orange fur and black stripes",
            "monkey": "A playful animal that swings from trees and eats bananas",
            
            "pizza": "A round flat bread with cheese and toppings",
            "banana": "A long yellow fruit that monkeys love",
            "chocolate": "A sweet brown candy or dessert",
            "sandwich": "Two pieces of bread with food in between",
            "cookie": "A small sweet baked treat, often with chocolate chips",
            "burger": "A round meat patty in a bun",
            "pasta": "Italian noodles often served with sauce",
            "salad": "A healthy dish made with lettuce and vegetables",
            "orange": "A round citrus fruit that is orange colored",
            "strawberry": "A small red fruit with seeds on the outside",
            
            "basketball": "A sport where you shoot a ball through a hoop",
            "football": "A sport played with an oval ball and touchdowns",
            "baseball": "A sport with bats, balls, and bases",
            "tennis": "A sport played with rackets over a net",
            "swimming": "Moving through water using your arms and legs",
            "soccer": "A sport where you kick a ball into a goal",
            "hockey": "A sport played on ice with sticks and a puck",
            "volleyball": "A sport where you hit a ball over a net",
            "boxing": "A fighting sport with gloves in a ring",
            "running": "Moving fast on your feet, often in races",
            
            "mountain": "A very tall natural elevation of land",
            "ocean": "A huge body of salt water",
            "forest": "A large area covered with trees",
            "desert": "A dry sandy area with little water",
            "river": "A long flowing body of water",
            "volcano": "A mountain that can erupt with lava",
            "beach": "A sandy shore by the ocean",
            "valley": "A low area between hills or mountains",
            "meadow": "A grassy field with wildflowers",
            "canyon": "A deep narrow valley with steep sides"
        ]
        
        return hints[word] ?? "Think about this word related to the category!"
    }
}

// MARK: - Game ViewModel

class GameViewModel: ObservableObject {
    @Published var words: [String] = []
    @Published var currentWordIndex = 0
    @Published var selectedAnswer: String? = nil
    @Published var attemptsRemaining = 2
    @Published var hint = "Loading..."
    @Published var isLoading = true
    @Published var isCorrect = false
    @Published var finalScore = 0
    @Published var multipleChoiceOptions: [String] = []
    @Published var showCorrectAnswer = false
    
    let category: String
    
    init(category: String) {
        self.category = category
    }
    
    func fetchWords() {
        WordAPIService.fetchWords(category: category) { [weak self] fetchedWords in
            guard let self = self else { return }
            self.words = fetchedWords
            self.isLoading = false
            if !fetchedWords.isEmpty {
                self.generateMultipleChoiceOptions()
                self.fetchHint()
            }
        }
    }
    
    func fetchHint() {
        guard currentWordIndex < words.count else { return }
        hint = "Loading hint..."
        
        DictionaryAPIService.fetchDefinition(for: words[currentWordIndex]) { [weak self] definition in
            self?.hint = definition
        }
    }
    
    func generateMultipleChoiceOptions() {
        guard currentWordIndex < words.count else { return }
        
        let correctAnswer = words[currentWordIndex]
        var options = [correctAnswer]
        
        // Get 3 wrong answers from other words in the list
        let otherWords = words.filter { $0 != correctAnswer }
        
        if otherWords.count >= 3 {
            let wrongAnswers = Array(otherWords.shuffled().prefix(3))
            options.append(contentsOf: wrongAnswers)
        } else {
            // If we don't have enough words, add all available
            options.append(contentsOf: otherWords)
        }
        
        // Shuffle all options so correct answer isn't always first
        multipleChoiceOptions = options.shuffled()
    }
    
    func validateGuess() -> Bool {
        guard currentWordIndex < words.count,
              let selected = selectedAnswer else { return false }
        return selected.lowercased() == words[currentWordIndex].lowercased()
    }
    
    func moveToNextWord() {
        currentWordIndex += 1
        selectedAnswer = nil
        attemptsRemaining = 2
        showCorrectAnswer = false
        
        if currentWordIndex < words.count {
            generateMultipleChoiceOptions()
            fetchHint()
        }
    }
    
    var isGameComplete: Bool {
        currentWordIndex >= words.count
    }
    
    var currentWord: String? {
        guard currentWordIndex < words.count else { return nil }
        return words[currentWordIndex]
    }
}

// MARK: - Custom ViewModifier: GameButtonStyle
struct GameButtonStyle: ViewModifier {
    let color: Color
    let isEnabled: Bool
    
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isEnabled ? color : Color.gray)
            )
            .scaleEffect(isEnabled ? 1.0 : 0.98)
    }
}

extension View {
    func gameButtonStyle(color: Color = .appAccent, isEnabled: Bool = true) -> some View {
        self.modifier(GameButtonStyle(color: color, isEnabled: isEnabled))
    }
}

// MARK: - Custom ViewModifier: CardStyle
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.appAccent.opacity(0.3), lineWidth: 1)
                    )
            )
    }
}

extension View {
    func cardStyle() -> some View {
        self.modifier(CardStyle())
    }
}

// MARK: - Haptic Manager

class HapticManager {
    static let shared = HapticManager()
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Accessibility Extension

extension View {
    func gameAccessibility(label: String, hint: String? = nil, value: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
    }
}

// MARK: - Custom View Component: MultipleChoiceButton

struct MultipleChoiceButton: View {
    let option: String
    let isSelected: Bool
    let isCorrect: Bool?
    let action: () -> Void
    
    var backgroundColor: Color {
        if let correct = isCorrect {
            return correct ? Color.green.opacity(0.3) : Color.red.opacity(0.3)
        } else if isSelected {
            return Color.appAccent.opacity(0.4)
        } else {
            return Color.appAccent.opacity(0.2)
        }
    }
    
    var borderColor: Color {
        if let correct = isCorrect {
            return correct ? Color.green : Color.red
        } else if isSelected {
            return Color.appAccent
        } else {
            return Color.appAccent.opacity(0.3)
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(option.capitalized)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
                
                if let correct = isCorrect {
                    Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(correct ? .green : .red)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: 2)
                    )
            )
        }
        .disabled(isCorrect != nil)
        .animation(.spring(response: 0.3), value: isSelected)
        .animation(.spring(response: 0.3), value: isCorrect)
        .gameAccessibility(
            label: option,
            hint: isSelected ? "Selected answer" : "Tap to select this answer"
        )
    }
}

// MARK: - Loading View

struct LoadingView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.appAccent.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.appAccent, Color.appSecondary]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(rotation))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: rotation)
            }
            
            Text("Loading words...")
                .foregroundColor(.white)
                .font(.headline)
        }
        .onAppear {
            rotation = 360
        }
    }
}

// MARK: - Custom View Component: CategoryCard

struct CategoryCard: View {
    let category: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            VStack(spacing: 15) {
                Text(icon)
                    .font(.system(size: 50))
                
                Text(category)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [color.opacity(0.6), color.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(color, lineWidth: 2)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3), value: isPressed)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Screen 3: Game View

struct GameView: View {
    @StateObject private var viewModel: GameViewModel
    @State private var showingAnswer = false
    @State private var answerIsCorrect = false
    @State private var showingNameEntry = false
    @State private var playerName = ""
    @Environment(\.modelContext) private var modelContext
    @AppStorage("highScore") private var highScore: Int = 0
    @AppStorage("favoriteCategory") private var favoriteCategory: String = "animals"
    @Environment(\.dismiss) var dismiss
    
    init(category: String) {
        _viewModel = StateObject(wrappedValue: GameViewModel(category: category))
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.isGameComplete {
                if showingNameEntry {
                    nameEntryView
                } else {
                    GameOverView(
                        score: viewModel.finalScore,
                        category: viewModel.category,
                        onPlayAgain: {
                            viewModel.currentWordIndex = 0
                            viewModel.finalScore = 0
                            viewModel.attemptsRemaining = 2
                            showingAnswer = false
                            viewModel.fetchWords()
                        },
                        onMainMenu: {
                            dismiss()
                        },
                        onSaveScore: {
                            showingNameEntry = true
                        }
                    )
                }
            } else {
                VStack(spacing: 20) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Text("Question \(viewModel.currentWordIndex + 1)/\(viewModel.words.count)")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        HStack(spacing: 5) {
                            ForEach(0..<viewModel.attemptsRemaining, id: \.self) { _ in
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    .padding()
                    
                    Text("Score: \(viewModel.finalScore)")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                        .animation(.spring(response: 0.5), value: viewModel.finalScore)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("💡 Hint")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(viewModel.hint)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
                    .padding(.horizontal)
                    
                    VStack(spacing: 15) {
                        Text("Select the correct word:")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        ForEach(viewModel.multipleChoiceOptions, id: \.self) { option in
                            MultipleChoiceButton(
                                option: option,
                                isSelected: viewModel.selectedAnswer == option,
                                isCorrect: showingAnswer ? (option.lowercased() == viewModel.currentWord?.lowercased()) : nil,
                                action: {
                                    if !showingAnswer {
                                        viewModel.selectedAnswer = option
                                        HapticManager.shared.selection()
                                    }
                                }
                            )
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    Button(action: checkAnswer) {
                        Text(showingAnswer ? "Next Question" : "Submit Answer")
                    }
                    .gameButtonStyle(
                        color: showingAnswer ? .green : .appAccent,
                        isEnabled: viewModel.selectedAnswer != nil || showingAnswer
                    )
                    .disabled(viewModel.selectedAnswer == nil && !showingAnswer)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            viewModel.fetchWords()
        }
    }
    
    var nameEntryView: some View {
        VStack(spacing: 30) {
            Text("🏆")
                .font(.system(size: 80))
            
            Text("Save Your Score!")
                .font(.title)
                .bold()
                .foregroundColor(.white)
            
            Text("Score: \(viewModel.finalScore)/4")
                .font(.title2)
                .foregroundColor(.appAccent)
            
            TextField("Enter your name", text: $playerName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 40)
            
            Button(action: {
                saveScore()
            }) {
                Text("Save & Continue")
            }
            .gameButtonStyle(isEnabled: !playerName.isEmpty)
            .disabled(playerName.isEmpty)
            .padding(.horizontal, 40)
            
            Button(action: { dismiss() }) {
                Text("Skip")
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
    }
    
    func saveScore() {
        let name = playerName.isEmpty ? "Anonymous" : playerName
        let score = PlayerScore(
            name: name,
            category: viewModel.category,
            score: viewModel.finalScore
        )
        
        // Insert into SwiftData
        modelContext.insert(score)
        
        // Update high score in AppStorage
        if viewModel.finalScore > highScore {
            highScore = viewModel.finalScore
        }
        
        dismiss()
    }
    
    func checkAnswer() {
        if showingAnswer {
            viewModel.moveToNextWord()
            showingAnswer = false
            answerIsCorrect = false
        } else {
            showingAnswer = true
            answerIsCorrect = viewModel.validateGuess()
            
            withAnimation(.spring(response: 0.5)) {
                if answerIsCorrect {
                    viewModel.finalScore += 1
                    HapticManager.shared.notification(type: .success)
                } else {
                    viewModel.attemptsRemaining -= 1
                    HapticManager.shared.notification(type: .error)
                }
            }
        }
    }
}

// MARK: - Game Over View

struct GameOverView: View {
    let score: Int
    let category: String
    let onPlayAgain: () -> Void
    let onMainMenu: () -> Void
    let onSaveScore: () -> Void
    
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text(score == 4 ? "🎉" : score >= 2 ? "😊" : "😅")
                .font(.system(size: 80))
                .scaleEffect(showContent ? 1.0 : 0.5)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showContent)
            
            Text("Game Over!")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
                .opacity(showContent ? 1 : 0)
                .animation(.easeIn(duration: 0.3).delay(0.2), value: showContent)
            
            Text("Final Score")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
                .opacity(showContent ? 1 : 0)
                .animation(.easeIn(duration: 0.3).delay(0.3), value: showContent)
            
            Text("\(score)/4")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.appAccent)
                .opacity(showContent ? 1 : 0)
                .animation(.easeIn(duration: 0.3).delay(0.4), value: showContent)
            
            VStack(spacing: 15) {
                Button(action: onSaveScore) {
                    Text("Save to Leaderboard")
                }
                .gameButtonStyle(color: .green)
                .opacity(showContent ? 1 : 0)
                .animation(.easeIn(duration: 0.3).delay(0.5), value: showContent)
                
                Button(action: onPlayAgain) {
                    Text("Play Again")
                }
                .gameButtonStyle(color: .appAccent)
                .opacity(showContent ? 1 : 0)
                .animation(.easeIn(duration: 0.3).delay(0.6), value: showContent)
                
                Button(action: onMainMenu) {
                    Text("Main Menu")
                }
                .gameButtonStyle(color: .white.opacity(0.2))
                .opacity(showContent ? 1 : 0)
                .animation(.easeIn(duration: 0.3).delay(0.7), value: showContent)
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            showContent = true
        }
    }
}

// MARK: - Screen 2: Leaderboard View

struct LeaderboardView: View {
    @Environment(\.dismiss) var dismiss
    @Query(sort: \PlayerScore.score, order: .reverse) private var scores: [PlayerScore]
    @AppStorage("highScore") private var highScore: Int = 0
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 5) {
                        Text("🏆 Leaderboard")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                        
                        if highScore > 0 {
                            Text("High Score: \(highScore)")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .opacity(0)
                }
                .padding()
                
                if scores.isEmpty {
                    VStack(spacing: 20) {
                        Text("📊")
                            .font(.system(size: 80))
                        
                        Text("No scores yet!")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text("Play a game to see your scores here")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(Array(scores.enumerated()), id: \.element.id) { index, score in
                            LeaderboardRow(
                                rank: index + 1,
                                name: score.name,
                                category: score.category,
                                score: score.score,
                                date: score.date
                            )
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
    }
}

// MARK: - Custom View Component: LeaderboardRow

struct LeaderboardRow: View {
    let rank: Int
    let name: String
    let category: String
    let score: Int
    let date: Date
    
    var rankEmoji: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "🏅"
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }
    
    var body: some View {
        HStack {
            Text(rankEmoji)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack {
                    Text(category)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("\(score)/4")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(dateFormatter.string(from: date))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appAccent.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appAccent.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.vertical, 5)
    }
}

// MARK: - Screen 1: Content View

struct ContentView: View {
    @State private var selectedCategory: String? = nil
    @State private var showLeaderboard = false
    @Query(sort: \PlayerScore.score, order: .reverse) private var scores: [PlayerScore]
    @AppStorage("highScore") private var highScore: Int = 0
    @AppStorage("favoriteCategory") private var favoriteCategory: String = "animals"
    
    let categories = [
        ("Animals", "🐾", Color.orange),
        ("Food", "🍎", Color.red),
        ("Sports", "⚽️", Color.green),
        ("Nature", "🌳", Color.mint)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 5) {
                            Text("🎮 Word Game")
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.white)
                            
                            Text("Choose a Category")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                            
                            if highScore > 0 {
                                Text("Your Best: \(highScore)/4")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            HapticManager.shared.impact(style: .light)
                            showLeaderboard = true
                        }) {
                            Image(systemName: "trophy.fill")
                                .font(.title2)
                                .foregroundColor(.yellow)
                        }
                    }
                    .padding()
                    
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 20) {
                            ForEach(categories, id: \.0) { category in
                                CategoryCard(
                                    category: category.0,
                                    icon: category.1,
                                    color: category.2,
                                    action: {
                                        favoriteCategory = category.0
                                        selectedCategory = category.0
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .fullScreenCover(item: Binding(
                get: { selectedCategory.map { CategoryWrapper(name: $0) } },
                set: { selectedCategory = $0?.name }
            )) { wrapper in
                GameView(category: wrapper.name)
            }
            .fullScreenCover(isPresented: $showLeaderboard) {
                LeaderboardView()
            }
        }
    }
}

// Helper struct
struct CategoryWrapper: Identifiable {
    let id = UUID()
    let name: String
}
