import SwiftUI

struct ToastOverlay: ViewModifier {
    @Binding var message: AppStore.ToastMessage?

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let message {
                HStack(spacing: 8) {
                    Image(systemName: message.isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    Text(message.text)
                }
                .font(.callout.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.primary.opacity(0.08)))
                .foregroundStyle(message.isError ? Theme.dangerRed : Theme.skodaGreen)
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .task(id: message.id) {
                    try? await Task.sleep(nanoseconds: 3_500_000_000)
                    if self.message?.id == message.id {
                        self.message = nil
                    }
                }
            }
        }
        .animation(.spring(duration: 0.3), value: message?.id)
    }
}

extension View {
    func toast(_ message: Binding<AppStore.ToastMessage?>) -> some View {
        modifier(ToastOverlay(message: message))
    }
}
