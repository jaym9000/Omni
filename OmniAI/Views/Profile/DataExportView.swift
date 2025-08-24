import SwiftUI

struct DataExportView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @Binding var isExporting: Bool
    @Binding var exportCompleted: Bool
    @State private var exportError: String?
    @State private var exportedData: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.omniPrimary)
                    
                    Text("Export Your Data")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.omniTextPrimary)
                    
                    Text("Download all your personal data including chat history, mood entries, and journal entries.")
                        .font(.system(size: 16))
                        .foregroundColor(.omniTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                // Export Options
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("What's included:", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.omniTextPrimary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Your profile information")
                            Text("• All chat conversations (decrypted)")
                            Text("• Mood tracking history")
                            Text("• Journal entries")
                            Text("• Account settings")
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.omniTextSecondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.omniSecondaryBackground)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Export Button
                Button(action: exportData) {
                    if isExporting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else if exportCompleted {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Export Complete")
                        }
                    } else {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Export My Data")
                        }
                    }
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    exportCompleted ? Color.green :
                    isExporting ? Color.gray :
                    Color.omniPrimary
                )
                .cornerRadius(28)
                .disabled(isExporting || exportCompleted)
                .padding(.horizontal)
                
                if let error = exportError {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                if exportCompleted {
                    Button(action: shareExportedData) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Exported Data")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.omniPrimary)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.omniPrimary)
                }
            }
        }
    }
    
    private func exportData() {
        guard let userId = authManager.currentUser?.id else {
            exportError = "User not found"
            return
        }
        
        isExporting = true
        exportError = nil
        
        Task {
            do {
                let data = try await FirebaseManager.shared.exportUserData(userId: userId)
                
                // Convert to JSON string
                let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
                exportedData = String(data: jsonData, encoding: .utf8) ?? ""
                
                await MainActor.run {
                    isExporting = false
                    exportCompleted = true
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    exportError = "Export failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func shareExportedData() {
        guard !exportedData.isEmpty else { return }
        
        // Create a temporary file
        let fileName = "OmniData_\(Date().timeIntervalSince1970).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try exportedData.write(to: tempURL, atomically: true, encoding: .utf8)
            
            // Share the file
            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        } catch {
            exportError = "Failed to share: \(error.localizedDescription)"
        }
    }
}

#Preview {
    DataExportView(isExporting: .constant(false), exportCompleted: .constant(false))
        .environmentObject(AuthenticationManager())
}